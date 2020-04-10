//
//  HTZPlayViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import GKCoverSwift

enum HTZPlayerPlayStyle: NSInteger {
    case loop = 0 // 循环播放
    case one = 1 // 单曲循环
    case random = 2 // 随机播放
}

class HTZPlayViewController: HTZBaseViewController {
    
    /// 循环类型
    var playStyle: HTZPlayerPlayStyle?
    
    /// 当前播放的音频的id
    var currentPlayId: String?
    
    /// 是否正在播放
    var isPlaying: Bool?
    
    
    static let sharedInstance = HTZPlayViewController()
    
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
    private var duration: TimeInterval? = 0
    /// 当前时间
    private var currentTime: TimeInterval? = 0
    /// 锁屏时的滑杆时间
    private var positionTime: TimeInterval? = 0
    
    /// 快进、快退定时器
    private var seekTimer: Timer?
    /// 是否立即播放
    private var ifNowPlay: Bool?
    /// seek进度
    private var toSeekProgress: CGFloat?
    
    private var cover: GKCover?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加通知
        addNotifications()

        // 设置播放器的代理
        kPlayer.delegate = self
        
        // 锁屏控制(这里只能设置一次，多次设置事件也会调用多次)
        self.setupLockScreenControlInfo()

    }
    
    @objc func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        HTZDownloadManager.sharedInstance.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HTZMusicTool.hidePlayBtn()
        self.isAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        HTZMusicTool.showPlayBtn()
        HTZDownloadManager.sharedInstance.delegate = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.isAppear = false
    }
    
    override func configSubView() {
        super.configSubView()
        self.view.backgroundColor = UIColor.white
        // 获取播放方式，并设置
        self.playStyle = HTZPlayerPlayStyle(rawValue: UserDefaults.Standard.integer(forKey: UserDefaults.keyPlayStyle))
        self.controlView.style = self.playStyle
        
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        self.view.addSubview(bgImageView)
//        // 添加毛玻璃效果
//        let tabbar = UITabBar()
//        tabbar.barStyle = UIBarStyle.black
//        bgImageView.addSubview(tabbar)
//        tabbar.snp.makeConstraints { (make) in
//            make.edges.equalTo(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
//        }
        
        self.view.addSubview(self.topLabel)
        self.view.addSubview(self.topLyricView)
        self.view.addSubview(self.middleLine)
        self.view.addSubview(self.bottomLabel)
        self.view.addSubview(self.bottomLyricView)
        self.view.addSubview(self.controlView)
    }

    
    override func configConstraint() {
        super.configConstraint()
        
        self.topLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).offset(2 * kGlobelMargin)
            make.left.equalTo(self.view).offset(2 * kGlobelMargin)
        }
       
        self.topLyricView.snp.makeConstraints { (make) in
            make.top.equalTo(self.topLabel.snp.bottom).offset(0.5 * kGlobelMargin)
            make.left.equalTo(self.topLabel)
            make.right.equalTo(self.view).offset(-2 * kGlobelMargin)
            make.height.equalTo(200)
        }
        
        self.middleLine.snp.makeConstraints { (make) in
            make.top.equalTo(self.topLyricView.snp.bottom).offset(2 * kGlobelMargin)
            make.left.right.equalTo(self.view)
            make.height.equalTo(1)
        }
        
        self.bottomLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.middleLine.snp.bottom).offset(kGlobelMargin)
            make.left.equalTo(self.topLabel)
        }
        
        self.bottomLyricView.snp.makeConstraints { (make) in
            make.top.equalTo(self.bottomLabel.snp.bottom).offset(0.5 * kGlobelMargin)
            make.left.right.equalTo(self.topLyricView)
            make.bottom.equalTo(self.controlView.snp.top)
        }
        
        self.controlView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.height.equalTo(170)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide)
            } else {
                make.bottom.equalTo(self.view)
            }
        }
    }
    
    
    deinit {
        // 移除监听
        NotificationCenter.default.removeObserver(self)
    }
    
    func lovedCurrentMusic() {
        self.model?.isLove = !(self.model!.isLove ?? false)
        HTZMusicTool.love(music: self.model!)
        self.controlView.is_love = self.model?.isLike
        
        NotificationCenter.default.post(name: NSNotification.Name.init(kLoveMusicNotification), object: nil)
    }
    
     lazy var leftBarButtonItem: UIBarButtonItem = {
            let button = UIButton(setImage: "downArrow", setBackgroundImage: "", target: self, action: #selector(back))
            let buttonItem = UIBarButtonItem(customView: button)
            button.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
            return buttonItem
        }()
        
        lazy var bgImageView: UIImageView = {
            let imageView = UIImageView(frame: self.view.bounds)
            return imageView
        }()
       
        lazy var controlView: HTZMusicControlView = {
            let controlView = HTZMusicControlView()
            controlView.delegate = self
            return controlView
        }()
        
        private lazy var topLabel: UILabel = {
            let label = UILabel()
            label.textColor = UIColor.darkGray
            label.text = "原文"
            label.font = UIFont.systemFont(ofSize: 16.0)
            return label
        }()
        lazy var topLyricView: HTZMusicLyricView = {
            let lyricView = HTZMusicLyricView()
            return lyricView
        }()
        lazy var middleLine: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.groupTableViewBackground
            return view
        }()
        private lazy var bottomLabel: UILabel = {
            let label = UILabel()
            label.textColor = UIColor.darkGray
            label.text = "讲解"
            label.font = UIFont.systemFont(ofSize: 16.0)
            return label
        }()
        private lazy var bottomLyricView: HTZMusicLyricView = {
            let lyricView = HTZMusicLyricView()
            return lyricView
        }()
        
        lazy var listView: HTZMusicListView = {
            let view = HTZMusicListView()
            view.delegate = self
            return view
        }()
        
    
}

// MARK: - addNotifications
extension HTZPlayViewController {
    
    private func addNotifications() {
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        // 插拔耳机
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChange(noti:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        // 播放打断
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruptionNotification(noti:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    //
    @objc private func audioSessionRouteChange(noti: Notification) {
        
        print(noti.userInfo as Any)
        let routeChange = noti.userInfo?[AVAudioSessionRouteChangeReasonKey]
        let routeChangeReson = AVAudioSession.RouteChangeReason(rawValue: routeChange as! UInt)
        switch routeChangeReson {
        case .newDeviceAvailable?:
            print("耳机插入")
            // 继续播放音频，什么也不用做
            break
        case .oldDeviceUnavailable?:
            print("耳机拔出")
            // 注意：拔出耳机时系统会自动暂停你正在播放的音频，因此只需要改变UI为暂停状态即可
            if let isPlaying = self.isPlaying, isPlaying {
                self.pauseMusic()
            }
            break
        default: break
            
        }
    }
    
    //
    @objc private func audioSessionInterruptionNotification(noti: Notification) {
        
        print(noti.userInfo as Any)
        
        // 获取类型
        let interruptionTypeOpt = noti.userInfo?[AVAudioSessionInterruptionTypeKey]
        let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeOpt as! UInt)
        let interruptionOptionOpt = noti.userInfo?[AVAudioSessionInterruptionOptionKey]
        var interruptionOption: AVAudioSession.InterruptionOptions?
        if let interruptionOptionOpt = interruptionOptionOpt {
            interruptionOption = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionOpt as! UInt)
        }
        
        if interruptionType == .began {
            // 收到播放中断的通知，暂停播放
            if let isPlaying = self.isPlaying, isPlaying {
                self.isInterrupt = true
                self.pauseMusic()
                self.isPlaying = false
            }
        } else if interruptionType == .ended {
            if let isInterrupt = self.isInterrupt, isInterrupt {
                self.isInterrupt = false
                // 中断结束，判断是否需要恢复播放
                if interruptionOption == AVAudioSession.InterruptionOptions.shouldResume {
                   
                    if let isPlaying = self.isPlaying, !isPlaying {
                        self.playMusic()
                        self.isPlaying = true
                    }                }
            }
        }
    }
}

extension HTZPlayViewController {
    
    /// 初始化播放器数据
    func initialData() {
        guard let musics = HTZMusicTool.musicList() else { return }
        
        // 获取历史播放内容及进度
        let playInfo = HTZMusicTool.lastMusicInfo()
        if playInfo != nil { // 如果有播放记录列表肯定不会为空
            // 播放状态
            self.playStyle = HTZPlayerPlayStyle(rawValue: HTZMusicTool.playStyle())
            // 设置播放器列表
            self.setPlayerList(playList: musics)
            
            // 获取索引，加载数据
            let index = HTZMusicTool.index(from: playInfo!["play_id"] as! String)
            
            self.loadMusic(index: index)
            
            self.toSeekProgress = playInfo!["play_progress"] as? CGFloat
            
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
        
        guard let playStyle = self.playStyle else { return }
        
        switch playStyle {
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
            NotificationCenter.default.post(name: NSNotification.Name(kPlayMusicChangeNotification), object: nil)
            self.model = model
            
            getMusicInfo()
        } else {
            self.ifNowPlay = true
            if let isPlaying = self.isPlaying, isPlaying {return}
            
            if let model = model {
                self.model = model
                // 已下载，直接用下载数据播放
                if self.model!.isDownload {
                    
                    getMusicInfo()
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
                getMusicInfo()
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
            
            NotificationCenter.default.post(name: NSNotification.Name(kPlayMusicChangeNotification), object: nil)
            
            self.model = model
            
            // TODO: - 获取歌词详细信息
            getMusicInfo()
        }
    }
    
    /// 获取歌曲详细信息
    private func getMusicInfo() {
        if let model = self.model {
            setupTitle(model: model)
        }
        
        if let palying = self.isPlaying, palying || kPlayer.playerState == HTZAudioPlayerState.paused {
             self.isPlaying = false
            self.stopMusic()
        }
        
        // 初始化数据
        self.topLyricView.lyrics = nil
        self.bottomLyricView.lyrics = nil
       
        self.controlView.initialData()
        
        if let ifNowPlay = self.ifNowPlay, ifNowPlay {
            self.controlView.showLoadingAnim()
        }
        
        self.controlView.is_love = self.model?.isLike
        self.controlView.is_download = self.model?.isDownload
        
        // TODO: - setupLockScreenMediaInfoNull
        self.setupLockScreenMediaInfo()
        
        if let model = self.model, model.isDownload {
            
            setupTitle(model: model)
            let duration = TimeInterval(model.file_duration!)
//            // 总时间
            self.controlView.totalTime = HTZMusicTool.timeStr(secTime: duration!)
            
            if let toSeekProgress = self.toSeekProgress, toSeekProgress > 0.0 {
                self.controlView.currentTime = HTZMusicTool.timeStr(secTime: duration! * TimeInterval(toSeekProgress))
                self.controlView.progress = toSeekProgress
            }
            // 设置播放地址
            kPlayer.playUrlStr = model.song_localPath
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                if let ifNowPlay = self.ifNowPlay, ifNowPlay {
                    kPlayer.play()
                }
            }
            var lyrics = HTZLyricParser.lyricParser(url: (self.model?.song_lyricPath)!, isDelBlank: true)
            
            if lyrics == nil {
               lyrics = HTZLyricParser.lyricParser(url: (self.model?.lrclink)!, isDelBlank: true)
            }
            // 解析歌词
            self.topLyricView.lyrics = lyrics
            self.bottomLyricView.lyrics = lyrics
        } else {
            if HTZMusicTool.networkState() == "none" {
                alert(message: "网络连接失败")
                return
            }
            if let model = self.model {
                setupTitle(model: model)
                let duration = TimeInterval(model.file_duration!)
                // 总时间
                self.controlView.totalTime = HTZMusicTool.timeStr(secTime: duration!)
                
                if let toSeekProgress = self.toSeekProgress, toSeekProgress > 0.0 {
                    self.controlView.currentTime = HTZMusicTool.timeStr(secTime: duration! * TimeInterval(toSeekProgress))
                    self.controlView.progress = toSeekProgress
                }
                // 设置播放地址
                kPlayer.playUrlStr = model.file_link
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    if let ifNowPlay = self.ifNowPlay, ifNowPlay {
                        kPlayer.play()
                    }
                }
                // 解析歌词
                self.topLyricView.lyrics = HTZLyricParser.lyricParser(lyricString: (self.model?.original)!, isDelBlank: true)
                self.bottomLyricView.lyrics = HTZLyricParser.lyricParser(lyricString: (self.model?.explanation)!, isDelBlank: true)
            }
            // 获取歌曲信息
            
//            NetWorkRequest(API.songDetail(songId: self.model!.song_id!), completion: { (responseObject) -> (Void) in
//                self.model = HTZMusicModel.deserialize(from: responseObject["songinfo"].rawString())
//                let bitrate = responseObject["bitrate"]
//                self.model?.file_link = bitrate["file_link"].rawString()
//                self.model?.file_duration = bitrate["file_duration"].rawString()
//                self.model?.file_size = bitrate["file_size"].rawString()
//                self.model?.file_extension = bitrate["file_extension"].rawString()
//
//                guard let model = self.model else {
//                    return
//                }
//
//                let duration = TimeInterval(model.file_duration!)
//                //            // 总时间
//                self.controlView.totalTime = HTZMusicTool.timeStr(secTime: duration!)
//
//                if let toSeekProgress = self.toSeekProgress, toSeekProgress > 0.0 {
//                    self.controlView.currentTime = HTZMusicTool.timeStr(secTime: duration! * TimeInterval(toSeekProgress))
//                    self.controlView.progress = toSeekProgress
//                }
//                // 设置播放地址
//                kPlayer.playUrlStr = model.file_link
//
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
//                    if let ifNowPlay = self.ifNowPlay, ifNowPlay {
//                        kPlayer.play()
//                    }
//                }
//                // 解析歌词
//                self.topLyricView.lyrics = HTZLyricParser.lyricParser(url: (self.model?.lrclink)!, isDelBlank: true)
//                self.bottomLyricView.lyrics = HTZLyricParser.lyricParser(url: (self.model?.lrclink)!, isDelBlank: true)
//            }) { (error) -> (Void) in
//                print("获取详情失败==\(error)")
//                self.alert(message: "数据请求失败，请检查网络后重试！")
//            }
        }
    }
    
    private func setupTitle(model: HTZMusicModel) {
        self.title = model.song_name
    }
}

// MARK: - HTZAudioPlayerDelegate
extension HTZPlayViewController: HTZAudioPlayerDelegate {
    

    // 播放状态改变
    @objc func playerStatusChanged(_ player: HTZAudioPlayer, _ status: HTZAudioPlayerState) {
        switch status {
        case .loading: // 加载中
            DispatchQueue.main.async {
                self.controlView.showLoadingAnim()
                self.controlView.setupPauseButton()

            }
            self.isPlaying = false
            break
        case .buffering: // 缓冲中
            DispatchQueue.main.async {
                self.controlView.hideLoadingAnim()
                self.controlView.setupPlayButton()
                if let isAppear = self.isAppear, isAppear {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2, execute: {

                    })
                }
            }
            self.isPlaying = true
            break
        case .playing: // 播放中
            DispatchQueue.main.async {
                self.controlView.hideLoadingAnim()
                self.controlView.setupPlayButton()
            }
            if let toSeekProgress = self.toSeekProgress, toSeekProgress > 0 {
                kPlayer.setPlayerProgress(progress: Float(toSeekProgress))
                self.toSeekProgress = 0
            }
            self.isPlaying = true
            break
        case .paused: // 暂停
            DispatchQueue.main.async {
                self.controlView.hideLoadingAnim()
                self.controlView.setupPauseButton()
                if let isChanged = self.isChanged, isChanged {
                    self.isChanged = false
                } else {
//                    self.c
                }
            }
            self.isPlaying = false
            break
        case .stoppedBy: // 主动停止
            DispatchQueue.main.async {
                self.controlView.hideLoadingAnim()
                self.controlView.setupPauseButton()
                if let isChanged = self.isChanged, isChanged {
                    self.isChanged = false
                } else {
                    //                    self.c
                    print("播放停止后暂停动画")
                }
            }
            self.isPlaying = false
            break
        case .stopped: // 打断停止
            DispatchQueue.main.async {
                self.controlView.hideLoadingAnim()
                self.controlView.setupPauseButton()
                self.pauseMusic()
            }
            self.isPlaying = false
            break
        case .ended: // 播放结束
            print("播放结束了")
            if let isPlaying = self.isPlaying, isPlaying {
                DispatchQueue.main.async {
                    self.controlView.hideLoadingAnim()
                    self.controlView.setupPauseButton()

                    self.controlView.currentTime = self.controlView.totalTime
                }
                self.isPlaying = false
                // 播放结束，自动播放下一首
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2, execute: {
                    self.isAutoPlay = true
                    self.playNextMusic()
                })
            } else {
                DispatchQueue.main.async {
                    self.controlView.hideLoadingAnim()
                    self.controlView.setupPauseButton()

                }
                self.isPlaying = false
            }

            break
        case .error: // 播放出错
            DispatchQueue.main.async {
                self.controlView.hideLoadingAnim()
                self.controlView.setupPauseButton()
                if let isAppear = self.isAppear, isAppear {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2, execute: {

                    })
                }
            }
            self.isPlaying = false
            break
        }
        NotificationCenter.default.post(name: NSNotification.Name(kPlayStateChangeNotification), object: nil)
    }
    
    // 播放进度改变
    @objc func playerProgress(_ player: HTZAudioPlayer, _ currentTime: TimeInterval, _ totalTime: TimeInterval, _ progress: Float) {
        // 记录播放id和进度
        let dict = ["play_id" : self.currentPlayId as Any, "play_progress" : progress] as [String : Any]
        UserDefaults.Standard.set(dict, forKey: UserDefaults.keyPlayInfo)
        
        if let isDraging = self.isDraging, isDraging { return }
        if let isSeeking = self.isSeeking, isSeeking { return }
        
        var progress = CGFloat(progress)
        if let toSeekProgress = self.toSeekProgress, toSeekProgress > 0 {
            progress = toSeekProgress
        }
        
        self.controlView.currentTime = HTZMusicTool.timeStr(msTime: currentTime)
        self.controlView.progress = progress
        
        // 更新锁屏信息
        self.setupLockScreenMediaInfo()
        
        // 歌词滚动
        guard let isPlaying = self.isPlaying, isPlaying else { return }
        
        self.topLyricView.scrollLyric(currentTime: currentTime, totalTime: totalTime)
        self.bottomLyricView.scrollLyric(currentTime: currentTime, totalTime: totalTime)
    }
    // 播放总时间
    @objc func playerTotalTime(_ player: HTZAudioPlayer, _ totalTime: TimeInterval) {
        self.controlView.totalTime = HTZMusicTool.timeStr(msTime: totalTime)
        self.duration = totalTime
    }
    
    // 缓冲进度改变
    @objc func playerBufferProgress(_ player: HTZAudioPlayer, _ bufferProgress: Float) {
        self.controlView.bufferProgress = CGFloat(bufferProgress)
    }
    
    
}

// MARK: - HTZMusicControlViewDelegate
extension HTZPlayViewController: HTZMusicControlViewDelegate {
    @objc func controlViewDidClickLove(_ controlView: HTZMusicControlView) {
        lovedCurrentMusic()
        if let model = self.model, model.isLike! {
            self.alert(message: "已添加到我喜欢的音乐")
        } else {
            self.alert(message: "已取消喜欢")
            
        }
    }
    
    @objc func controlViewDidClickDownload(_ controlView: HTZMusicControlView) {
        print("下载")
        if let model = self.model {
            if model.isDownload {
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
                if let model = self.model, let downloadState = model.downloadState {
                            switch downloadState {
                                
                            case .none: // 未开始
                                model.downloadState = .downloading
                                HTZMusicTool.downloadMusic(musicModel: model)
                                break
                            case .waiting: // 等待下载
                                break
                            case .downloading: // 下载中
                //                self.alert(message: "下载中")
                                self.alertConfirmCacellActionAlert(title: "", message: "下载中", leftConfirmTitle: "下载暂停", rightConfirmTitle: "不取消", selectLeftBlock: {
                                    model.downloadState = .paused
                                    let dModel = HTZDownloadModel()
                                    dModel.fileID = model.song_id
                                    dModel.fileName = model.song_name
                                    dModel.fileAlbumId = model.album_id
                                    dModel.fileAlbumName = model.album_title
                                    dModel.fileCover = model.icon
                                    dModel.fileUrl = model.file_link
                                    dModel.fileDuration = model.file_duration
                                    dModel.fileLyric = model.lrclink
                                    kDownloadManager.pausedDownloadArr(downloadArr: [dModel])
                                }, selectRightBlock: nil)
                                break
                            case .paused: // 下载暂停
                                 self.alertConfirmCacellActionAlert(title: "", message: "下载暂停", leftConfirmTitle: "继续下载", rightConfirmTitle: "取消", selectLeftBlock: {
                                                    model.downloadState = .downloading
                                                   let dModel = HTZDownloadModel()
                                                   dModel.fileID = model.song_id
                                                   dModel.fileAlbumId = model.album_id
                                                   kDownloadManager.resumeDownloadArr(downloadArr: [dModel])
                                               }, selectRightBlock: nil)
                                break
                            case .failed:  // 下载失败
                                break
                            case .finished:  // 下载完成
                                self.alertConfirmCacellActionAlert(title: "", message: "该歌曲已下载，是否删除下载", leftConfirmTitle: "删除", rightConfirmTitle: "取消", selectLeftBlock: {
                                    let dModel = HTZDownloadModel()
                                    dModel.fileID = model.song_id
                                    dModel.fileAlbumId = model.album_id
                                    kDownloadManager.deleteDownloadModelArr(modelArr: [dModel])
                                }, selectRightBlock: nil)
                                break
                            
                            }
                        }
                
                //            HTZMusicTool.downloadMusic(songId: model.song_id!)
            }
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
        UserDefaults.Standard.set(self.playStyle?.rawValue, forKey: UserDefaults.keyPlayStyle)
        
    }
    
    @objc func controlViewDidClickPlay(_ controlView: HTZMusicControlView) {
        
        if let isPlaying = self.isPlaying, isPlaying {
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.isChanged = true
            self.playNextMusic()
        }
    }
    
    @objc func controlViewDidClickList(_ controlView: HTZMusicControlView) {
        print("controlViewDidClickList")
        
        var rect = self.listView.frame
        rect.size = CGSize(width: kScreenWidth, height: 440)
        self.listView.frame = rect
        self.listView.dataArr = self.musicList as! [HTZMusicModel]
        
        cover = GKCover(fromView: self.navigationController!.view, contentView: self.listView, style: .Translucent, showStyle: .Bottom, showAnimStyle: .Bottom, hideAnimStyle: .Bottom, notClick: false, showBlock: {}) {}
        cover!.show()
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderTouchBegan value: CGFloat) {
        self.isDraging = true
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderTouchEnded value: CGFloat) {
        self.isDraging = false
        if let isPlaying = self.isPlaying, isPlaying {
            kPlayer.setPlayerProgress(progress: Float(value))
        } else {
            self.toSeekProgress = value
        }
        
        // TODO: - 滚动歌词到对应位置
        self.topLyricView.scrollLyric(currentTime: self.duration! * TimeInterval(value), totalTime: self.duration!)
        self.bottomLyricView.scrollLyric(currentTime: self.duration! * TimeInterval(value), totalTime: self.duration!)
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderValueChange value: CGFloat) {
        self.isDraging = true
        self.controlView.currentTime = HTZMusicTool.timeStr(msTime: self.duration ?? 0 * TimeInterval(value))
    }
    
    @objc func controlView(_ controlView: HTZMusicControlView, didSliderTapped value: CGFloat) {
        self.controlView.currentTime = HTZMusicTool.timeStr(msTime: self.duration! * TimeInterval(value))
        
        if self.isPlaying! {
            kPlayer.setPlayerProgress(progress: Float(value))
        } else {
            self.toSeekProgress = value
        }
        // TODO: - 滚动歌词到对应位置
        self.topLyricView.scrollLyric(currentTime: self.duration! * TimeInterval(value), totalTime: self.duration!)
        self.bottomLyricView.scrollLyric(currentTime: self.duration! * TimeInterval(value), totalTime: self.duration!)
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
    
    private func randomArray(arr: [HTZMusicModel]) -> [HTZMusicModel] {
        var list = arr
        for index in 0..<list.count {
            let newIndex = Int(arc4random_uniform(UInt32(list.count-index))) + index
            if index != newIndex {
                list.swapAt(index, newIndex)
            }
        }
        return list
    }
}

// MARK: - setupLockScreenControlInfo
extension HTZPlayViewController {
    
    private func setupLockScreenControlInfo() {
        let commandCenter = MPRemoteCommandCenter.shared()
        // 锁屏播放
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            print("锁屏暂停后点击播放")
            
            if let isPlaying = self.isPlaying, !isPlaying {
                self.playMusic()
            }
            return MPRemoteCommandHandlerStatus.success
        }
        
        // 锁屏暂停
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            print("锁屏正在播放点击后暂停")
            if let isPlaying = self.isPlaying, isPlaying {
                self.pauseMusic()
            }
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.stopCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            self.pauseMusic()
            return MPRemoteCommandHandlerStatus.success
        }
        
        // 播放和暂停按钮（耳机控制）
        let playPauseCommand = commandCenter.togglePlayPauseCommand
        playPauseCommand.isEnabled = true
        playPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if let isPlaying = self.isPlaying {
                if isPlaying {
                    self.pauseMusic()
                } else {
                    self.playMusic()
                }
            }
             return MPRemoteCommandHandlerStatus.success
        }
        
        // 上一曲
        let previousCommand = commandCenter.previousTrackCommand
        previousCommand.isEnabled = true
        previousCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playPrevMusic()
            return MPRemoteCommandHandlerStatus.success
        }
        
        // 下一曲
        let nextCommand = commandCenter.nextTrackCommand
        nextCommand.isEnabled = true
        nextCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.isAutoPlay = false
            if let isPlaying = self.isPlaying, isPlaying {
                self.pauseMusic()
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                self.isChanged = true
                self.playNextMusic()
            })
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        // 快进
        let forwardCommand = commandCenter.seekForwardCommand
        forwardCommand.isEnabled = true
        forwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            
            let seekEvent = event as! MPSeekCommandEvent
            if seekEvent.type == MPSeekCommandEventType.beginSeeking {
                self.seekingForwardStart()
            } else {
                self.seekingForwardStop()
            }
            return MPRemoteCommandHandlerStatus.success
        }
        
        // 快退
        let backwardCommand = commandCenter.seekBackwardCommand
        backwardCommand.isEnabled = true
        backwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let seekEvent = event as! MPSeekCommandEvent
            if seekEvent.type == MPSeekCommandEventType.beginSeeking {
                self.seekingBackwardStart()
            } else {
                self.seekingBackwardStop()
            }
            return MPRemoteCommandHandlerStatus.success
        }
        
        // 拖动进度条
        commandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let positionEvent = event as! MPChangePlaybackPositionCommandEvent
            if positionEvent.positionTime != self.positionTime {
                self.positionTime = positionEvent.positionTime
                self.currentTime = self.positionTime! * 1000
                kPlayer.setPlayerProgress(progress: Float(self.currentTime! / self.duration!))
            }
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    private func setupLockScreenMediaInfo() {
        
        let playingCenter = MPNowPlayingInfoCenter.default()
        
        var playingInfo = [MPMediaItemPropertyAlbumTitle : self.model?.album_title ?? "",
                           MPMediaItemPropertyTitle : self.model?.song_name ?? "",
                           MPMediaItemPropertyArtist: self.model?.song_name ?? ""] as [String : Any]
        
        let image: UIImage
        if let placeholderImage = self.bgImageView.image {
            image = placeholderImage
        } else {
            image = UIImage()
        }
        
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
            return image
        })
        
        playingInfo[MPMediaItemPropertyArtwork] = artwork
        var duration: TimeInterval = 0
        if let d = self.duration {
            duration = d
        }
        var progress: TimeInterval = 0
        if let p = self.controlView.progress {
            progress = TimeInterval(p)
        }
        // 当前播放的时间
        playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = (duration * progress) / 1000
        // 进度的速度
        playingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        // 总时间
        playingInfo[MPMediaItemPropertyPlaybackDuration] = duration / TimeInterval(1000)
        playingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = progress
        
        playingCenter.nowPlayingInfo = playingInfo
    }
    
    /// 快进开始
    private func seekingForwardStart() {
        
        guard let isPlaying = self.isPlaying, isPlaying else { return }
        self.isSeeking = true
        self.currentTime = TimeInterval(self.controlView.progress ?? 0) * (self.duration ?? 0)
        self.seekTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(seekingForwardAction), userInfo: nil, repeats: true)
    }
    
    /// 快进结束
    private func seekingForwardStop() {
        guard let isPlaying = self.isPlaying, isPlaying else { return }
        guard self.seekTimer != nil else { return }
        self.isSeeking = false
        self.seekTimeInvalidated()
        var duration:TimeInterval = 0
        if let d = self.duration {
            duration = d
        }
        kPlayer.setPlayerProgress(progress: Float(self.currentTime! / duration))
    }
    
    @objc private func seekingForwardAction() {
        guard let currentTime = self.currentTime else { return }
        var duration:TimeInterval = 0
        if let d = self.duration {
            duration = d
        }
        if currentTime >= duration {
            self.seekTimeInvalidated()
        } else {
            var currentTimeD = Double(currentTime)
            currentTimeD += 1000
            self.currentTime = TimeInterval(currentTimeD)
            var duration:TimeInterval = 0
            if let d = self.duration {
                duration = d
            }
            self.controlView.progress = duration == 0 ? 0.0 : CGFloat(self.currentTime! / duration)
            self.controlView.currentTime = HTZMusicTool.timeStr(msTime: currentTimeD)
        }
    }
    
    /// 快退开始
    private func seekingBackwardStart() {
        
        guard let isPlaying = self.isPlaying, isPlaying else { return }
        self.isSeeking = true
        self.currentTime = TimeInterval(self.controlView.progress ?? 0) * (self.duration ?? 0)
        self.seekTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(seekingBackwardAction), userInfo: nil, repeats: true)
    }
    
    /// 快退结束
    private func seekingBackwardStop() {
        guard let isPlaying = self.isPlaying, isPlaying else { return }
        guard self.seekTimer != nil else { return }
        self.isSeeking = false
        self.seekTimeInvalidated()
        var duration:TimeInterval = 0
        if let d = self.duration {
            duration = d
        }
        kPlayer.setPlayerProgress(progress: Float(self.currentTime! / duration))
    }
    
    @objc private func seekingBackwardAction() {
        guard let currentTime = self.currentTime else { return }
        if currentTime <= 0 {
            self.seekTimeInvalidated()
        } else {
            var currentTimeD = Double(currentTime)
            currentTimeD -= 1000
            self.currentTime = TimeInterval(currentTimeD)
            var duration:TimeInterval = 0
            if let d = self.duration {
                duration = d
            }
            self.controlView.progress = duration == 0 ? 0.0 : CGFloat(self.currentTime! / duration)
        }
    }
    
    private func seekTimeInvalidated()  {
        if let seekTimer = self.seekTimer {
            seekTimer.invalidate()
            self.seekTimer = nil
        }
    }
}

// MARK: - HTZMusicListViewDeleagate
extension HTZPlayViewController: HTZMusicListViewDeleagate {
    
    @objc internal func listViewDidClickLoop(_ listView: HTZMusicListView) {
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
        
        self.listView.style = self.playStyle
        UserDefaults.Standard.set(self.playStyle?.rawValue, forKey: UserDefaults.keyPlayStyle)
        
    }
    
    @objc internal func listViewDidClickClose(_ listView: HTZMusicListView) {
        cover!.hide()
    }
    
    
    @objc internal func listViewDidSelect(_ listView: HTZMusicListView, _ selectRow: NSInteger) {
        cover!.hide()
        self.playMusic(index: selectRow, isSetList: false)
    }
    
    
    
}

// MARK: - HTZDownloadManagerDelegate
extension HTZPlayViewController: HTZDownloadManagerDelegate {
    @objc func downloadChanged(_ downloadManager: HTZDownloadManager, downloadModel: HTZDownloadModel, state: HTZDownloadManagerState) {
        // 下载的是当前播放的
        if let model = self.model, model.song_id == downloadModel.fileID {
            if state == HTZDownloadManagerState.finished { // 下载完成
                DispatchQueue.main.async {
                    // 改变状态
                    self.controlView.is_download = self.model?.isDownload
                }
            }
        }
    }
    
    
    @objc func removedDownloadArr(_ downloadManager: HTZDownloadManager, downloadArr: [HTZDownloadModel]) {
        
    }
    
    @objc func downloadProgress(_ downloadManager: HTZDownloadManager, downloadModel: HTZDownloadModel, totalSize: NSInteger, downloadSize: NSInteger, progress: Float) {
        print(progress)
    }
    
}

