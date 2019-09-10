//
//  HTZPlayViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import AVFoundation

enum HTZPlayerPlayStyle: NSInteger {
    case loop = 0 // 循环播放
    case one = 1 // 单曲循环
    case random = 2 // 随机播放
}

class HTZPlayViewController: BaseViewController {
    
    /// 循环类型
    var playStyle: HTZPlayerPlayStyle?
    
    /// 当前播放的音频的id
    var currentPlayId: String?
    
    /// 是否正在播放
    var isPlaying: Bool?
    
    static let sharedInstance = HTZPlayViewController()
    
    lazy var controlView: HTZMusicControlView = {
        let controlView = HTZMusicControlView()
        controlView.delegate = self
        return controlView
    }()
    
    
    /// 音乐原始播放列表
    private var musicList: [HTZMusicModel?] = []
    /// 当前播放的列表,包括乱序后的列表
    private var playList: [HTZMusicModel?] = []
    private var model: HTZMusicModel?
    
    /// 是否自动播放，用于切换歌曲
    private var isAutoPlay: Bool?
    /// 是否正在拖拽进度条
    private var isDraging: Bool?
    /// 是否在快进快退，锁屏时操作
    private var isSeeking: Bool?
    /// 是否正在切换歌曲，点击上一曲下一曲按钮
    private var isChanged: Bool?
    /// 是否点击暂停
    private var isPaused: Bool?
    
    /// 是否显示播放器页
    private var isAppear: Bool?
    /// 是否被打断
    private var isInterrupt: Bool?
    
    /// 总时间
    private var duration: TimeInterval?
    /// 当前时间
    private var currentTime: TimeInterval?
    /// 锁屏时的滑杆时间
    private var positionTime: TimeInterval?
    
    /// 快进、快退定时器
    private var seekTimer: Timer?
    /// 是否立即播放
    private var ifNowPlay: Bool?
    /// seek进度
    private var toSeekProgress: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //   接收打断的通知
//        NotificationCenter.default.addObserver(self, selector: #selector(nextMusic), name: NSNotification.Name(rawValue: kPlayFinishNotificationName), object: nil)
        
        //   接收打断的通知
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruptionNotification(noti:)), name: AVAudioSession.interruptionNotification, object: nil)

    }
    
    override func configSubView() {
        super.configSubView()
        
        
        self.view.addSubview(self.controlView)
    }

    
    override func configConstraint() {
        super.configConstraint()
        
        self.controlView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(170)
        }
    }
    
    
    deinit {
        // 移除监听
        NotificationCenter.default.removeObserver(self)
    }
    
    func lovedCurrentMusic() {
        self.model?.isLove = !self.model!.isLove!
        HTZMusicTool.love(music: self.model!)
        self.controlView.is_love = self.model?.isLike
        
        NotificationCenter.default.post(name: NSNotification.Name.init(loveMusicNotification), object: nil)
    }
    
}

extension HTZPlayViewController {
    
    /// 初始化播放器数据
    func initialData() {
        guard let musics = HTZMusicTool.musicList() else { return }
        
        // 获取历史播放内容及进度
        let playInfo = HTZMusicTool.lastMusicInfo()
        if let playInfo = playInfo { // 如果有播放记录列表肯定不会为空
            // 播放状态
            self.playStyle = HTZPlayerPlayStyle(rawValue: HTZMusicTool.playStyle())
            // 设置播放器列表
            self.setPlayerList(playList: musics)
            
            // 获取索引，加载数据
            let index = HTZMusicTool.index(from: playInfo["play_id"] as! String)
            
            self.loadMusic(index: index)
            
            self.toSeekProgress = playInfo["play_progress"] as? CGFloat
            
        } else {
//            HTZMusicTool.h
        }
    }
    
    /// 重置播放器id列表
    ///
    /// - Parameter playList: 列表
    func setPlayerList(playList: [HTZMusicModel]) {
        self.musicList = playList
        
        // 保存列表
        HTZMusicTool.save(musicList: playList)
        
        switch self.playStyle! {
        case .loop:
            self.playList = playList
            self.setCoverList()
            break
        case .one:
            self.playList = playList
            self.setCoverList()
            break
        case .random:
            self.playList = self.randomArray(arr: playList)
            self.setCoverList()
            break
        }
    }
    
    ///  播放指定位置的音乐
    ///
    /// - Parameters:
    ///   - index: 指定位置的索引
    ///   - isSetList: 是否需要设置列表
    func playMusic(index: NSInteger, isSetList: Bool) {
        let model = self.playList[index]
        if let model = model, model.song_id != self.currentPlayId {
            self.currentPlayId = model.song_id
            self.toSeekProgress = 0
            self.ifNowPlay = true
            if isSetList {
//                 [self.coverView setMusicList:self.playList idx:index]
            }
            NotificationCenter.default.post(name: NSNotification.Name(playMusicChangeNotification), object: nil)
            self.model = model
            
//            [self getMusicInfo];
        } else {
            self.ifNowPlay = true
            if self.isPlaying! {return}
            if let model = model {
                self.model = model
                // 已下载，直接用下载数据播放
                if self.model!.isDownload {
                    
//                    [self getMusicInfo]
                    return
                }
                // 播放
                self.playMusic()
            }
        }
    }
    
    /// 播放单个音频
    ///
    /// - Parameter model: 单个音频数据模型
    func playMusic(model: HTZMusicModel) {
        var playList = self.playList
        var index = 0
        var exist = false
        
        for (idx, _) in playList.enumerated() {
            index = idx
            exist = true
            break
        }
        
        if exist {
            self.playMusic(index: index, isSetList: false)
        } else {
            playList.append(model)
            
            self.setPlayerList(playList: playList as! [HTZMusicModel])
            index = playList.firstIndex(where: { (model) -> Bool in
                return true
            })!
            
            self.playMusic(index: index, isSetList: true)
        }
    }
    
    /// 播放
    func playMusic() {
        // 首先检查网络状态
        let networkState = HTZMusicTool.networkState()
        if networkState == "none" {
            alert(message: "网络连接失败")
            // 设置播放状态为暂停
            self.controlView.setupPauseButton()
            return
        } else {
            if kPlayer.playUrlStr == nil { // 没有播放地址
                // 需要重新请求
//                [self getMusicInfo];
            } else {
                if kPlayer.playerState == HTZAudioPlayerState.stopped {
                    kPlayer.play()
                } else if kPlayer.playerState == HTZAudioPlayerState.paused {
                    kPlayer.resume()
                } else {
                    kPlayer.play()
                }
            }
            
        }
    }
    
    /// 暂停
    func pauseMusic() {
        kPlayer.pause()
    }
    
    /// 停止
    func stopMusic() {
        kPlayer.stop()
    }
    
    /// 下一曲
    func playNextMusic() {
        // 重置封面
//        [self.coverView resetCoverView];
        // 播放
        if self.playStyle == HTZPlayerPlayStyle.loop {
            var currentIndex = 0
            for (idx, obj) in self.playList.enumerated() {
                if obj?.song_id == self.model?.song_id {
                    currentIndex = idx
                    break
                }
            }
            self.playNextMusic(index: currentIndex)
        } else if self.playStyle == HTZPlayerPlayStyle.one {
            if self.isAutoPlay! { // 循环播放自动播放完毕
                var currentIndex = 0
                for (idx, obj) in self.playList.enumerated() {
                    if obj?.song_id == self.model?.song_id {
                        currentIndex = idx
                        break
                    }
                }
                // 重置列表
//                [self.coverView resetMusicList:self.playList idx:currentIndex];
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                  
                    self.playMusic()
                }
            } else { // 循环播放切换歌曲
                var currentIndex = 0
                for (idx, obj) in self.playList.enumerated() {
                    if obj?.song_id == self.model?.song_id {
                        currentIndex = idx
                        break
                    }
                }
                self.playNextMusic(index: currentIndex)
            }
        } else {
            if self.playList.count == 0 {
                self.playList = self.randomArray(arr: self.musicList as! [HTZMusicModel])
            }
            // 找出乱序后当前播放歌曲的索引
            var currentIndex = 0
            for (idx, obj) in self.playList.enumerated() {
                if obj?.song_id == self.model?.song_id {
                    currentIndex = idx
                    break
                }
            }
            self.playNextMusic(index: currentIndex)
        }
    }
    
    private func playNextMusic(index: NSInteger) {
        var index = index
        if index < self.playList.count - 1 {
            index += 1
        } else {
            index = 0
        }
        
        // 切换到下一首
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
//            [self.coverView scrollChangeDiskIsNext:YES finished:^{
//                [self playMusicWithIndex:index isSetList:YES];
//                }]
            self.playMusic(index: index, isSetList: true)
        }
    }
    
    /// 上一曲
    func playPrevMusic() {
        // 重置封面
//        [self.coverView resetCoverView];
        // 播放
        if self.playStyle == HTZPlayerPlayStyle.loop {
            var currentIndex = 0
            for (idx, obj) in self.playList.enumerated() {
                if obj?.song_id == self.model?.song_id {
                    currentIndex = idx
                    break
                }
            }
            self.playPrevMusic(index: currentIndex)
        } else if self.playStyle == HTZPlayerPlayStyle.one {
            var currentIndex = 0
            for (idx, obj) in self.playList.enumerated() {
                if obj?.song_id == self.model?.song_id {
                    currentIndex = idx
                    break
                }
            }
            self.playPrevMusic(index: currentIndex)
        } else {
            if self.playList.count == 0 {
                self.playList = self.randomArray(arr: self.musicList as! [HTZMusicModel])
            }
            // 找出乱序后当前播放歌曲的索引
            var currentIndex = 0
            for (idx, obj) in self.playList.enumerated() {
                if obj?.song_id == self.model?.song_id {
                    currentIndex = idx
                    break
                }
            }
            self.playPrevMusic(index: currentIndex)
        }
    }
    
    private func playPrevMusic(index: NSInteger) {
        // 列表已经打乱顺序，直接播放上一首一首即可
        var index = index
        if index > 0 {
            index -= 1
        } else {
            index = self.playList.count - 1
        }
        
        // 切换到下一首
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            //            [self.coverView scrollChangeDiskIsNext:YES finished:^{
            //                [self playMusicWithIndex:index isSetList:YES];
            //                }]
            self.playMusic(index: index, isSetList: true)
        }
    }
    
    private func loadMusic(index: NSInteger) {
        let model = self.playList[index]
        
        if let model = model, model.song_id != self.currentPlayId {
            // TODO: - 设置coverView列表
//            [self.coverView setMusicList:self.playList idx:index];
            self.currentPlayId = model.song_id
            self.ifNowPlay = false
            
            NotificationCenter.default.post(name: NSNotification.Name(playMusicChangeNotification), object: nil)
            
            self.model = model
            
            // TODO: - 获取歌词详细信息
//            [self getMusicInfo];
        }
    }
}

extension HTZPlayViewController: HTZMusicControlViewDelegate {
    @objc func controlViewDidClickLove(_ controlView: HTZMusicControlView) {
        lovedCurrentMusic()
        if let model = self.model, model.isLike {
            self.alert(message: "已添加到我喜欢的音乐")
        } else {
            self.alert(message: "已取消喜欢")
            
        }
    }
    
    @objc func controlViewDidClickDownload(_ controlView: HTZMusicControlView) {
        print("下载")
        if let model = self.model, model.isDownload {
            
            let alertController = UIAlertController(title: nil, message: "该歌曲已下载，是否删除下载文件？", preferredStyle: UIAlertController.Style.alert)
            
            let leftAction = UIAlertAction(title: "删除", style: UIAlertAction.Style.default) { (action) in
                let dModel = HTZDownloadModel()
                dModel.fileID = model.song_id
                kDownloadManager.removeDownloadArr(downloadArr: [dModel])
            }
            alertController.addAction(leftAction)
            
            alertController.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
        } else {
            HTZMusicTool.downloadMusic(songId: self.model!.song_id!)
        }
    }
    
    @objc func controlViewDidClickLoop(_ controlView: HTZMusicControlView) {
        if self.playStyle == HTZPlayerPlayStyle.loop { // 循环->单曲
            self.playStyle = HTZPlayerPlayStyle.one
            self.playList = self.musicList
            
            self.setCoverList()
        } else if self.playStyle == HTZPlayerPlayStyle.one { // 单曲->随机
            self.playStyle = HTZPlayerPlayStyle.random
            self.playList = self.randomArray(arr: self.musicList as! [HTZMusicModel])
            
            self.setCoverList()
        } else { // 随机-> 循环
            self.playStyle = HTZPlayerPlayStyle.loop
            self.playList = self.musicList
            
            self.setCoverList()
        }
        
        self.controlView.style = self.playStyle
        
        UserDefaults.Standard.set(self.playStyle, forKey: UserDefaults.keyPlayStyle)
    }
    
    @objc func controlViewDidClickPlay(_ controlView: HTZMusicControlView) {
        if self.isPlaying! {
            self.pauseMusic()
        } else {
            self.playMusic()
        }
    }
    
    @objc func controlViewDidClickPrev(_ controlView: HTZMusicControlView) {
        
        self.isChanged = true
        if self.isPlaying! {
            self.stopMusic()
        }
        
        DispatchQueue.main.async {
            self.playPrevMusic()
        }
    }
    
    @objc func controlViewDidClickNext(_ controlView: HTZMusicControlView) {
        
        self.isAutoPlay = false
        if self.isPlaying! {
            self.stopMusic()
        }
    }
    
    @objc func controlViewDidClickList(_ controlView: HTZMusicControlView) {
        print("controlViewDidClickList")
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderTouchBegan value: CGFloat) {
        self.isDraging = true
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderTouchEnded value: CGFloat) {
        self.isDraging = false
        if self.isPlaying! {
            kPlayer.setPlayerProgress(progress: Float(value))
        } else {
            self.toSeekProgress = value
        }
        
        // TODO: - 滚动歌词到对应位置
//        [self.lyricView scrollLyricWithCurrentTime:(self.duration * value) totalTime:self.duration]
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderValueChange value: CGFloat) {
        self.isDraging = true
        self.controlView.currentTime = HTZMusicTool.timeStr(msTime: self.duration! * TimeInterval(value))
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderTapped value: CGFloat) {
        self.controlView.currentTime = HTZMusicTool.timeStr(msTime: self.duration! * TimeInterval(value))
        
        if self.isPlaying! {
            kPlayer.setPlayerProgress(progress: Float(value))
        } else {
            self.toSeekProgress = value
        }
        // TODO: - 滚动歌词到对应位置
        //        [self.lyricView scrollLyricWithCurrentTime:(self.duration * value) totalTime:self.duration]
    }
    
    private func setCoverList() {
        var currentIndex = 0
        for (idx, obj) in self.playList.enumerated() {
            if obj?.song_id == self.model?.song_id {
                currentIndex = idx
                break
            }
        }
        // TODO: - 重置列表
//        [self.coverView resetMusicList:self.playList idx:currentIndex];
    }
    
    // TODO: - 需要实现
    private func randomArray(arr: [HTZMusicModel]) -> [HTZMusicModel] {
//        (arr as NSArray).sortedArray { (obj1, obj2) -> ComparisonResult in
//            let seed = arc4random_uniform(2)
//            if seed != 0 {
//
//                return ((obj1 as! HTZMusicModel).song_id?.compare((obj2 as! HTZMusicModel).song_id))!
//            } else {
//
//            }
//        }
        return arr
    }
}

extension HTZPlayViewController {
    
    //
    @objc private func audioSessionInterruptionNotification(noti: Notification) {
     
        print(noti.userInfo)
        
        // 获取类型
        let type = noti.userInfo?[AVAudioSessionInterruptionTypeKey] as! AVAudioSession.InterruptionType
//        if type == AVAudioSession.InterruptionType.began {
//            // 暂停音乐
//            self.playButton.isSelected = true
//            playOrPauseMusic()
//        } else if type == AVAudioSession.InterruptionType.ended {
//            // 播放音乐
//            self.playButton.isSelected = false
//            playOrPauseMusic()
//            // 暂停音乐
//            self.playButton.isSelected = true
//            playOrPauseMusic()
//            // 播放音乐
//            self.playButton.isSelected = false
//            playOrPauseMusic()
//        }
    }
    
}

