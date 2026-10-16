import Foundation
import AVFoundation
import Combine

@MainActor
public final class AudioEngine {
    public static let shared = AudioEngine()

    private var player: AVPlayer
    private var playerItem: AVPlayerItem?
    private var playerItemStatusObserver: AnyCancellable?
    private var timeObserverToken: Any?
    private var didPlayToEndObserver: AnyCancellable?
    private var interruptionObserver: AnyCancellable?

    private var currentPlayerState: PlayerState {
        didSet { PlaybackBroadcaster.shared.yield(currentPlayerState) }
    }

    private var isSessionConfigured = false

    private init() {
        self.player = AVPlayer()
        self.currentPlayerState = PlayerState()
        PlaybackBroadcaster.shared.yield(currentPlayerState)
    }

    public func play(item: PlayerItem) async {
        #if DEBUG
        print("[HTZDebug] AudioEngine play requested: url=\(item.url)")
        #endif
        configureAudioSessionIfNeeded()
        player.pause()
        removeObservers()
        playerItem = AVPlayerItem(url: item.url)
        player.replaceCurrentItem(with: playerItem)
        observePlayerItem()
        let rate = Float(currentPlayerState.rate == 0 ? 1 : currentPlayerState.rate)
        player.play()
        if rate != 1 {
            player.rate = rate
        }

        var newState = PlayerState(currentItem: item, isPlaying: true, rate: Double(rate), didFinish: false, error: nil)
        if let duration = playerItem?.duration.seconds, duration.isFinite, !duration.isNaN {
            newState.duration = duration
        }
        self.currentPlayerState = newState
        addPeriodicTimeObserver()
    }

    public func resume() async {
        guard !currentPlayerState.isPlaying else { return }
        let rate = Float(currentPlayerState.rate == 0 ? 1 : currentPlayerState.rate)
        player.play()
        if rate != 1 {
            player.rate = rate
        }
        currentPlayerState.isPlaying = true
        currentPlayerState.didFinish = false
    }

    public func pause() async {
        guard currentPlayerState.isPlaying else { return }
        player.pause()
        currentPlayerState.isPlaying = false
    }

    public func seek(to seconds: Double) async {
        let clamped = max(0, seconds)
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        await player.seek(to: time)
        currentPlayerState.currentTime = clamped
        currentPlayerState.didFinish = false
    }

    public func setRate(_ rate: Double) async {
        let clamped = min(2, max(0.75, rate))
        currentPlayerState.rate = clamped
        if currentPlayerState.isPlaying {
            player.rate = Float(clamped)
        }
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
                .sink { notification in
                    Task { @MainActor in
                        await AudioEngine.shared.handleAudioSessionInterruption(notification: notification)
                    }
                }
        } catch {
            #if DEBUG
            print("[HTZDebug] AudioSession configuration failed: \(error)")
            #endif
            currentPlayerState.error = error.localizedDescription
        }
    }

    private func observePlayerItem() {
        playerItemStatusObserver = playerItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                Task { @MainActor in
                    AudioEngine.shared.handlePlayerItemStatusChange(status: status)
                }
            }
        didPlayToEndObserver = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                Task { @MainActor in
                    AudioEngine.shared.handleDidPlayToEndTime()
                }
            }
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            Task { @MainActor in
                AudioEngine.shared.updatePlaybackProgress(time: time)
            }
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
        #if DEBUG
        print("[HTZDebug] AVPlayerItem status changed: status=\(status.rawValue), error=\(String(describing: playerItem?.error))")
        #endif
        switch status {
        case .readyToPlay:
            if let duration = playerItem?.duration.seconds, duration.isFinite, !duration.isNaN {
                currentPlayerState.duration = duration
            }
            currentPlayerState.error = nil
            if currentPlayerState.isPlaying, player.rate == 0 {
                let rate = Float(currentPlayerState.rate == 0 ? 1 : currentPlayerState.rate)
                player.play()
                if rate != 1 {
                    player.rate = rate
                }
            }
        case .failed:
            let errorDescription = playerItem?.error?.localizedDescription ?? "Unknown playback error"
            #if DEBUG
            print("[HTZDebug] AVPlayerItem playback failed: \(errorDescription)")
            #endif
            currentPlayerState.error = errorDescription
            currentPlayerState.isPlaying = false
        default:
            break
        }
    }

    private func handleDidPlayToEndTime() {
        currentPlayerState.isPlaying = false
        currentPlayerState.didFinish = true
    }

    private func handleAudioSessionInterruption(notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            await pause()
        } else if type == .ended,
                  let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
            await resume()
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
}
