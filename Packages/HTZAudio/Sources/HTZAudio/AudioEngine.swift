import Foundation
import AVFoundation
import Combine

public actor AudioEngine {
    public static let shared = AudioEngine()

    private let stateStreamContinuation: AsyncStream<PlayerState>.Continuation
    public nonisolated let stateStream: AsyncStream<PlayerState>

    private var player: AVPlayer
    private var playerItem: AVPlayerItem?
    private var playerItemStatusObserver: AnyCancellable?
    private var timeObserverToken: Any?
    private var didPlayToEndObserver: AnyCancellable?
    private var interruptionObserver: AnyCancellable?

    private var currentPlayerState: PlayerState {
        didSet {
            stateStreamContinuation.yield(currentPlayerState)
        }
    }

    private var isSessionConfigured = false

    private init() {
        self.player = AVPlayer()
        self.currentPlayerState = PlayerState()

        let streamTuple = AsyncStream.makeStream(of: PlayerState.self, bufferingPolicy: .unbounded)
        self.stateStream = streamTuple.stream
        self.stateStreamContinuation = streamTuple.continuation

        self.stateStreamContinuation.yield(self.currentPlayerState)
    }

    public func play(item: PlayerItem) async {
        configureAudioSessionIfNeeded()
        player.pause()
        removeObservers()
        playerItem = AVPlayerItem(url: item.url)
        player.replaceCurrentItem(with: playerItem)
        observePlayerItem()
        player.play()

        var newState = PlayerState(currentItem: item, isPlaying: true, error: nil)
        // Best-effort duration; handlePlayerItemStatusChange updates it when .readyToPlay fires
        if let duration = playerItem?.duration.seconds, duration.isFinite, !duration.isNaN {
            newState.duration = duration
        }
        self.currentPlayerState = newState
        addPeriodicTimeObserver()
    }

    public func resume() async {
        guard !currentPlayerState.isPlaying else { return }
        player.play()
        currentPlayerState.isPlaying = true
    }

    public func pause() async {
        guard currentPlayerState.isPlaying else { return }
        player.pause()
        currentPlayerState.isPlaying = false
    }

    private func configureAudioSessionIfNeeded() {
        guard !isSessionConfigured else { return }
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            isSessionConfigured = true

            interruptionObserver = NotificationCenter.default
                .publisher(for: AVAudioSession.interruptionNotification)
                .sink { [weak self] notification in
                    Task { await self?.handleAudioSessionInterruption(notification: notification) }
                }
        } catch {
            currentPlayerState.error = error.localizedDescription
        }
    }

    private func observePlayerItem() {
        playerItemStatusObserver = playerItem?.publisher(for: \.status).sink { [weak self] status in
            Task { await self?.handlePlayerItemStatusChange(status: status) }
        }
        didPlayToEndObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem).sink { [weak self] _ in
            Task { await self?.handleDidPlayToEndTime() }
        }
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { await self?.updatePlaybackProgress(time: time) }
        }
    }

    private func updatePlaybackProgress(time: CMTime) {
        guard time.isValid, time.isNumeric else { return }
        currentPlayerState.currentTime = time.seconds
        if currentPlayerState.duration == 0, let duration = playerItem?.duration.seconds, duration.isFinite, !duration.isNaN {
            currentPlayerState.duration = duration
        }
    }

    private func handlePlayerItemStatusChange(status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            if let duration = playerItem?.duration.seconds, duration.isFinite, !duration.isNaN {
                currentPlayerState.duration = duration
            }
            currentPlayerState.error = nil
        case .failed:
            let errorDescription = playerItem?.error?.localizedDescription ?? "Unknown playback error"
            currentPlayerState.error = errorDescription
            currentPlayerState.isPlaying = false
        default: break
        }
    }

    private func handleDidPlayToEndTime() {
        currentPlayerState.isPlaying = false
    }

    private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            Task { await pause() }
        } else if type == .ended,
                  let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
            Task { await resume() }
        }
    }

    private func removeObservers() {
        playerItemStatusObserver?.cancel()
        didPlayToEndObserver?.cancel()
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    deinit {
        removeObservers()
        interruptionObserver?.cancel()
        if isSessionConfigured { try? AVAudioSession.sharedInstance().setActive(false) }
        stateStreamContinuation.finish()
    }
}
