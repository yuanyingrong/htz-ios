//
//  HTZAudioPlayer.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/9.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import FreeStreamer

// 播放器播放状态
enum HTZAudioPlayerState {
    case loading          // 加载中
    case buffering        // 缓冲中
    case playing          // 播放
    case paused           // 暂停
    case stoppedBy        // 停止（用户切换歌曲时调用）
    case stopped          // 停止（播放器主动发出：如播放被打断）
    case ended            // 结束（播放完成）
    case error             // 错误
}

// 播放器缓冲状态
enum HTZAudioBufferState {
    case none
    case buffering
    case finished
}

protocol HTZAudioPlayerDelegate: NSObjectProtocol {
    
    /// 播放器状态改变
    func playerStatusChanged(player: HTZAudioPlayer, status: HTZAudioPlayerState)
    
    /// 播放时间（单位：毫秒)、总时间（单位：毫秒）、进度（播放时间 / 总时间）
    func playerProgress(player: HTZAudioPlayer, currentTime: TimeInterval, totalTime: TimeInterval, progress: Float)
    
    /// 总时间（单位：毫秒）
    func playerTotalTime(player: HTZAudioPlayer, totalTime: TimeInterval)
    
    /// 缓冲进度
    func playerBufferProgress(player: HTZAudioPlayer, bufferProgress: Float)
}

class HTZAudioPlayer: NSObject {
    
    static let sharedInstance = HTZAudioPlayer()
    
    /// 播放状态
    var playerState: HTZAudioPlayerState?
    
    /// 缓冲状态
    var bufferState: HTZAudioBufferState?
    
    /// 播放地址（网络或本地）
    var playUrlStr: String? {
        willSet {
            if playUrlStr != newValue {
                // 切换数据，清除缓存
                self.removeCache()

                playUrlStr = newValue
            }
        }
        
        didSet {
            
            if let playUrlStr = playUrlStr, playUrlStr.hasSuffix("http") {
                DispatchQueue.main.async {
                    self.audioStream.url = NSURL(string: playUrlStr)
                }
            } else {
                DispatchQueue.main.async {
                    if let playUrlStr = self.playUrlStr {
                       self.audioStream.url = NSURL(fileURLWithPath: playUrlStr)
                    }
                }
            }
        }
//        get {
//            return playUrlStr
//        }
//        set {
//            if playUrlStr != newValue {
//                // 切换数据，清除缓存
//                self.removeCache()
//
//                playUrlStr = newValue
//
//                if playUrlStr.hasSuffix("http") {
//                    DispatchQueue.main.async {
//                        self.audioStream.url = NSURL(string: playUrlStr)
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        self.audioStream.url = NSURL(fileURLWithPath: playUrlStr)
//                    }
//                }
//            }
//        }
        
    }
    
    weak var delegate: HTZAudioPlayerDelegate?
    
    private var playTimer: Timer?
    private var bufferTimer: Timer?
    
    private lazy var audioStream: FSAudioStream = {
        let configuration = FSStreamConfiguration()
        let audioStream = FSAudioStream(configuration: configuration)
        audioStream?.strictContentTypeChecking = false
        audioStream?.defaultContentType = "audio/x-m4a"
        
        audioStream?.onCompletion = {
            print("完成")
        }
        weak var weakSelf = self
        audioStream?.onStateChange = { (state: FSAudioStreamState) in
            
            switch state {
            case .fsAudioStreamRetrievingURL: //检索url
                print("检索url")
                self.playerState = .loading
                
            case .fsAudioStreamStopped: // 停止
                
                // 切换歌曲时主动调用停止方法也会走这里，所以这里添加判断，区分是切换歌曲还是被打断等停止
                if (self.playerState != .stoppedBy && self.playerState != .ended) {
                    print("播放停止被打断")
                    self.playerState = .stopped
                }
            case .fsAudioStreamBuffering: // 缓冲
                print("缓冲中。。")
                weakSelf?.playerState = .buffering
                weakSelf?.bufferState = HTZAudioBufferState.buffering
                
            case .fsAudioStreamPlaying: // 播放
                print("播放中。。")
                weakSelf?.playerState = HTZAudioPlayerState.playing
                
            case .fsAudioStreamPaused: // 暂停
                print("播放暂停")
                weakSelf?.playerState = HTZAudioPlayerState.paused
                
            case .fsAudioStreamSeeking: // seek
                print("seek中。。")
                weakSelf?.playerState = HTZAudioPlayerState.loading
                
            case .fsAudioStreamEndOfFile:  // 缓冲结束
                print("缓冲结束")
                
                if self.bufferState == HTZAudioBufferState.finished { return }
                // 定时器停止后需要再次调用获取进度方法，防止出现进度不准确的情况
                weakSelf?.bufferTimerAction()
                
                weakSelf?.stopBufferTimer()
                
            case .fsAudioStreamFailed:  // 播放失败
                print("播放失败")
                weakSelf?.playerState = HTZAudioPlayerState.error
                
            case .fsAudioStreamRetryingStarted: // 检索开始
                print("检索开始")
                weakSelf?.playerState = HTZAudioPlayerState.loading
                
            case .fsAudioStreamRetryingSucceeded: // 检索成功
                print("检索成功")
                weakSelf?.playerState = HTZAudioPlayerState.loading
                
            case .fsAudioStreamRetryingFailed:   // 检索失败
                print("检索失败")
                weakSelf?.playerState = HTZAudioPlayerState.error
                
            case .fsAudioStreamPlaybackCompleted: // 播放完成
                print("播放完成")
                weakSelf?.playerState = HTZAudioPlayerState.ended
                
            case .fsAudioStreamUnknownState:  // 未知状态
                print("未知状态")
                weakSelf?.playerState = HTZAudioPlayerState.error
                
            @unknown default: break
                
            }
            self.setupPlayerState(state: weakSelf!.playerState!)
        }
        return audioStream!
    }()
    
    override init() {
        super.init()
        self.playerState = HTZAudioPlayerState.stopped
    }
    
    /// 快进、快退
    ///
    /// - Parameter progress: 进度
    func setPlayerProgress(progress: Float) {
        var progress = progress
        if progress == 0 { progress = 0.001 }
        if progress == 1 { progress = 0.999 }
        
        var position = FSStreamPosition()
        position.position = progress
        
        DispatchQueue.main.async {
            self.audioStream.seek(to: position)
        }
    }
    
    /// 设置播放速率 0.5 - 2.0， 1.0是正常速率
    ///
    /// - Parameter playRate: 速率
    func setPlayerPlayRate(playRate: Float) {
        var playRate = playRate
        if playRate < 0.5 { playRate = 0.5 }
        if playRate > 2.0 { playRate = 2.0 }
        
        DispatchQueue.main.async {
            self.audioStream.setPlayRate(playRate)
        }
    }
    
    /// 播放
    func play() {
        if self.playerState == HTZAudioPlayerState.playing { return }
        
        assert(self.playUrlStr == nil, "url不能为空")

        
        DispatchQueue.main.async {
            self.audioStream.play()
        }
        
        self.startTimer()
        
        // 如果缓冲未完成
        if (self.bufferState != HTZAudioBufferState.finished) {
            self.bufferState = HTZAudioBufferState.none
            self.startBufferTimer()
        }
    }
    
    /// 从某个进度开始播放
    ///
    /// - Parameter progress: 进度
    func playFromProgress(progress: Float) {
        var offset = FSSeekByteOffset()
        offset.position = progress
        
        DispatchQueue.main.async {
            self.audioStream.play(from: offset)
        }
        
        self.startTimer()
        
        // 如果缓冲未完成
        if (self.bufferState != HTZAudioBufferState.finished) {
            self.bufferState = HTZAudioBufferState.none
            self.startBufferTimer()
        }
    }
    
    /// 暂停
    func pause() {
        if self.playerState == HTZAudioPlayerState.paused { return }
        
        self.playerState = HTZAudioPlayerState.paused
        self.setupPlayerState(state: self.playerState!)
        
        DispatchQueue.main.async {
            self.audioStream.pause()
        }
        
        self.stopTimer()
    }
    
    /// 恢复（暂停后再次播放使用）
    func resume() {
        if self.playerState == HTZAudioPlayerState.playing { return }
        
        DispatchQueue.main.async {
            // 这里恢复播放不能用play，需要用pause
            self.audioStream.pause()
        }
        
        self.startTimer()
    }
    
    /// 停止
    func stop() {
        if self.playerState == HTZAudioPlayerState.stopped { return }
        
        self.playerState = HTZAudioPlayerState.stoppedBy
        self.setupPlayerState(state: self.playerState!)
        
        DispatchQueue.main.async {
            self.audioStream.stop()
        }
        
        self.stopTimer()
    }
    
    private func removeCache() {
        DispatchQueue.main.async {
            do {
                let arr = try FileManager.default.contentsOfDirectory(atPath: self.audioStream.configuration.cacheDirectory)
                for filePath in arr {
                    if (filePath.hasPrefix("FSCache-")) {
                        let path = "\(String(describing: self.audioStream.configuration.cacheDirectory))/\(filePath)"
                       try FileManager.default.removeItem(atPath: path)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func setupPlayerState(state: HTZAudioPlayerState) {
        if let delegate = self.delegate, delegate.responds(to: Selector(("playerStatusChanged::"))) {
            delegate.playerStatusChanged(player: self, status: state)
        }
    }
    
    private func startTimer() {
        if self.playTimer == nil {
            self.playTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
    }
    
    private func stopTimer() {
        if self.playTimer != nil {
            self.playTimer?.invalidate()
            self.playTimer = nil
        }
    }
    
    private func startBufferTimer() {
        if self.bufferTimer == nil {
            self.bufferTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(bufferTimerAction), userInfo: nil, repeats: true)
        }
    }
    
    private func stopBufferTimer() {
        self.bufferTimer?.invalidate()
        self.bufferTimer = nil
    }
    
    
    @objc private func timerAction() {
        
        DispatchQueue.main.async {
            let cur = self.audioStream.currentTimePlayed
            let currentTime = cur.playbackTimeInSeconds * 1000
            let totalTime = self.audioStream.duration.playbackTimeInSeconds * 1000
            let progress = cur.position
            
            if let delegate = self.delegate, delegate.responds(to: Selector(("playerProgress::::"))) {
                delegate.playerProgress(player: self, currentTime: TimeInterval(currentTime), totalTime: TimeInterval(totalTime), progress: progress)
            }
            
            if let delegate = self.delegate, delegate.responds(to: Selector(("playerTotalTime::"))) {
                delegate.playerTotalTime(player: self, totalTime: TimeInterval(totalTime))
            }
        }
    }
    
    @objc private func bufferTimerAction() {
        
        DispatchQueue.main.async {
            
            let preBuffer = Float(self.audioStream.prebufferedByteCount)
            let contentLength = Float(self.audioStream.contentLength)
            
            // 这里获取的进度不能准确地获取到1
            var bufferProgress = contentLength > 0 ? preBuffer / contentLength : 0.0
            
            // 为了能使进度准确的到1，这里做了一些处理
            let buffer = Int(bufferProgress + 0.5)
            
            if (bufferProgress > 0.9 && buffer >= 1) {
                self.bufferState = HTZAudioBufferState.finished
                self.stopBufferTimer()
                // 这里把进度设置为1，防止进度条出现不准确的情况
                bufferProgress = 1.0
                
                print("缓冲结束了，停止进度");
            } else {
                self.bufferState = HTZAudioBufferState.buffering
            }
            
            if let delegate = self.delegate, delegate.responds(to: Selector(("playerBufferProgress::"))) {
                delegate.playerBufferProgress(player: self, bufferProgress: bufferProgress)
            }
        }
    }
    
    deinit {
        
        self.playTimer?.invalidate()
        self.playTimer = nil
        self.bufferTimer?.invalidate()
        self.bufferTimer = nil
    }

}