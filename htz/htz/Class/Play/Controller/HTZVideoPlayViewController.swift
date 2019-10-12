//
//  HTZVideoPlayViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/9.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZVideoPlayViewController: HTZBaseViewController {
    
    
    var player: IJKFFMoviePlayerController?
    
    var urlStr: String
    
    var smallPreViewFrame = CGRect()
    
    private var isMediaSliderBeingDragged: Bool = false
    
    init(urlStr: String) {
        self.urlStr = urlStr
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        installMovieNotificationObservers()
        
        self.player?.prepareToPlay() //准备
        self.player?.play() //播放
        
        refreshMediaControl()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.player?.pause()//暂停
        self.player?.shutdown()
        
        removeMovieNotificationObservers()
    }
    
    @objc func refreshMediaControl() {
        let duration = self.player?.duration
        let intDuration = NSInteger(duration! + 0.5)
        if intDuration > 0 {
            self.slider.maximumValue = Float(duration!)
        } else {
            self.slider.maximumValue = 0.0
        }
        // position
        var position: TimeInterval?
        if isMediaSliderBeingDragged {
            position = TimeInterval(self.slider.value)
        } else {
            position = self.player?.currentPlaybackTime
        }
        let intPosition = NSInteger(position! + 0.5)
        if intDuration > 0 {
            self.slider.value = Float(position!)
        } else {
            self.slider.value = 0.0
        }
        
        // status
//        let isPlaying = self.player?.isPlaying()
//        self.playButton
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshMediaControl), object: nil)
        perform(#selector(refreshMediaControl), with: nil, afterDelay: 0.5)
//        if (!self.overlayPanel.hidden) {
//            [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
//        }
    }
    
    
    
    @objc func fullScreen() {
//        let vc = HTZVideoPlayFullViewController(urlStr: self.urlStr)
//        vc.player = self.player
//        self.navigationController?.pushViewController(vc, animated: true)
        enterFullScreen()
    }
    
    //进入全屏模式
    func enterFullScreen() {
        
        self.fullBackButton.isHidden = false
        self.fullScreenButton.isHidden = true
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.blockRotation = true
        DeviceTool.interfaceOrientation(.landscapeLeft)
        
        self.smallPreViewFrame = self.preView.frame
        let rectInWindow = self.preView.convert(self.preView.bounds, to: UIApplication.shared.keyWindow)
        self.preView.removeFromSuperview()
        self.preView.frame = rectInWindow
        UIApplication.shared.keyWindow?.addSubview(self.preView)
        
        weak var weakSelf = self
        UIView.animate(withDuration: 0.5, animations: {
//            weakSelf!.preView.transform = weakSelf!.preView.transform.rotated(by: .pi / 2)
//            weakSelf!.preView.bounds = CGRect(x: 0, y: 0, width: max(kScreenWidth, kScreenHeight), height: min(kScreenWidth, kScreenHeight))
//            weakSelf!.preView.center = CGPoint(x: weakSelf!.preView.superview!.bounds.midX, y: weakSelf!.preView.superview!.bounds.midY)
            weakSelf!.preView.snp.makeConstraints { (make) in
                make.edges.equalTo((UIApplication.shared.keyWindow)!)
                
            }
        }) { (isFinished) in
            
        }
    }
     
     
    //退出全屏
    @objc func exitFullScreen() {
        
        self.fullBackButton.isHidden = true
        self.fullScreenButton.isHidden = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.blockRotation = false
        DeviceTool.interfaceOrientation(.portrait)
        
        let frame = self.view.convert(self.smallPreViewFrame, to: UIApplication.shared.keyWindow)
        weak var weakSelf = self
        UIView.animate(withDuration: 0.5, animations: {
//            self.preView.transform = CGAffineTransform.identity
//            self.preView.frame = frame
        }) { (isFinished) in
            // 回到小屏位置
            self.preView.removeFromSuperview()
            self.preView.frame = self.smallPreViewFrame
            self.view.addSubview(self.preView)
            
            
            weakSelf!.preView.snp.makeConstraints { (make) in
                make.left.right.equalTo(weakSelf!.view)
                make.top.equalTo(weakSelf!.view.snp.topMargin)
                make.height.equalTo(250)
            }
        }
    }
    
    override func configSubView() {
            super.configSubView()
            
            
    //        let url: URL = URL.init(string: "http://htzshanghai.top/resources/videos/others/never_give_up.mp4")!
        #if DEBUG
            IJKFFMoviePlayerController.setLogReport(true)
            IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_DEBUG)
        #else
            IJKFFMoviePlayerController.setLogReport(false)
            IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_INFO)
        #endif
            IJKFFMoviePlayerController.checkIfFFmpegVersionMatch(true)
            
            let options: IJKFFOptions = IJKFFOptions.byDefault()
            
            self.player = IJKFFMoviePlayerController.init(contentURL: URL(string: urlStr), with: options)
            var arm1 = UIView.AutoresizingMask()
            arm1.insert(UIView.AutoresizingMask.flexibleWidth)
            arm1.insert(UIView.AutoresizingMask.flexibleHeight)
            self.player?.view.autoresizingMask = arm1
            self.player?.view.backgroundColor = UIColor.white
            
    //        self.player?.view.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 300)
            
    //        self.player?.scalingMode = .aspectFit
            self.player?.shouldAutoplay = true
    //        self.view.autoresizesSubviews = true
            
//            preView.frame = CGRect(x: 0, y: 88, width: kScreenWidth, height: 300)
            view.addSubview(preView)
            
            self.player?.view.frame = preView.bounds
            preView.addSubview((self.player?.view)!)
            
            preView.addSubview(self.slider)
            preView.addSubview(self.playButton)
            preView.addSubview(fullBackButton)
            preView.addSubview(fullScreenButton)
        }
    
    override func configConstraint() {
        super.configConstraint()
        weak var weakSelf = self
        
        preView.snp.makeConstraints { (make) in
            make.left.right.equalTo(weakSelf!.view)
            make.top.equalTo(weakSelf!.view.snp.topMargin)
            make.height.equalTo(250)
        }
        
        playButton.snp.makeConstraints { (make) in
            make.left.equalTo(weakSelf!.preView).offset(16)
            make.centerY.equalTo(weakSelf!.slider)
        }
        self.slider.snp.makeConstraints { (make) in
            make.left.equalTo(weakSelf!.playButton.snp.right)
//            make.right.equalTo(weakSelf!.preView)
            make.bottom.equalTo(weakSelf!.preView)
        }
        
        
     
        
        fullScreenButton.snp.makeConstraints { (make) in
            make.left.equalTo(weakSelf!.slider.snp.right)
            make.right.equalTo(weakSelf!.preView).offset(-16)
            make.centerY.equalTo(weakSelf!.slider)
        }
        
        fullBackButton.snp.makeConstraints { (make) in
            make.top.left.equalTo(weakSelf!.preView).offset(16)
            make.size.equalTo(CGSize(width: 66, height: 32))
        }
        
    }
    
    private lazy var preView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "stop"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "play"), for: UIControl.State.selected)
        button.addTarget(self, action: #selector(playOrPause), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var fullScreenButton: UIButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("全屏", for: .normal)
        button.addTarget(self, action: #selector(fullScreen), for: .touchUpInside)
        return button
    }()
    
    private lazy var fullBackButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(exitFullScreen), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider()
        
        //设置默认值
        slider.value = 0.1
        //设置Slider值，并有动画效果
        slider.setValue(0.5, animated: true)
        //设置Slider两边槽的颜色
        slider.minimumTrackTintColor = UIColor.red
        slider.maximumTrackTintColor = UIColor.green
        //添加两边槽图片
        slider.minimumValueImage = UIImage(named: "image")
        slider.maximumValueImage = UIImage(named: "image1")
        //设置Slider组件图片
        slider.setMaximumTrackImage(UIImage(named:"Maximage1"), for: .normal)
        slider.setMinimumTrackImage(UIImage(named:"MinImage2"), for: .normal)
        slider.setThumbImage(UIImage(named: "thumInage"), for: .normal)
        //使用三宫格缩放
        let image = UIImage(named: "image3")?.stretchableImage(withLeftCapWidth: 14, topCapHeight: 0)//左右像素为14px，中间缩放
        slider.setMaximumTrackImage(image, for: .normal)
        //Slider值改变响应
        slider.isContinuous = false//设置在停止滑动时才出发响应事件
        slider.addTarget(self, action: #selector(didSliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(didSliderTouchCancel), for: .touchCancel)
        slider.addTarget(self, action: #selector(didSliderTouchUpOutside), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(didSliderTouchUpInside), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        //添加到视图中
        self.view.addSubview(slider)
        
        return slider
    }()
    
   
    @objc func didSliderTouchDown() {
           print(slider.value)
        self.isMediaSliderBeingDragged = true
       }
    @objc func didSliderTouchCancel() {
           print(slider.value)
           self.isMediaSliderBeingDragged = false
       }
    @objc func didSliderTouchUpOutside() {
        print(slider.value)
        self.isMediaSliderBeingDragged = false
    }
    @objc func didSliderTouchUpInside() {
        print(slider.value)
        self.player!.currentPlaybackTime = TimeInterval(self.slider.value)
        self.isMediaSliderBeingDragged = false
    }
    @objc func sliderChanged(_ slider: UISlider) {
           print(slider.value)
           refreshMediaControl()
       }
//    lazy var slider: HTZSliderView = {
//        let slider = HTZSliderView()
//        slider.setBackgroundImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.normal)
//        slider.setBackgroundImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.selected)
//        slider.setBackgroundImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.highlighted)
//
//        slider.setThumbImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.normal)
//        slider.setThumbImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.selected)
//        slider.setThumbImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.highlighted)
//
//        slider.maximumTrackImage = UIImage(named: "read_classics_icon_normal")
//        slider.minimumTrackImage = UIImage(named: "read_classics_icon_normal")
//        slider.bufferTrackImage = UIImage(named: "read_classics_icon_normal")
//
//        slider.delegate = self
//        slider.sliderHeight = 2
//
//        return slider
//    }()
}

/// HTZSliderViewDelegate
extension HTZVideoPlayViewController: HTZSliderViewDelegate {
    func sliderTouchBegin(_ value: CGFloat) {
        
    }
    
    func sliderValueChanged(_ value: CGFloat) {
        
    }
    
    func sliderTouchEnded(_ value: CGFloat) {
        
    }
    
    func sliderTapped(_ value: CGFloat) {
        
    }
    
    
}

/// 按钮点击事件
extension HTZVideoPlayViewController {
    
    @objc private func playOrPause() {
        if (self.player?.isPlaying())! {
            self.playButton.isSelected = true
            self.player?.pause()
        } else {
            self.playButton.isSelected = false
            self.player?.play()
        }
    }
}
/// 通知
extension HTZVideoPlayViewController {
    
    private func installMovieNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadStateDidChange(noti:)), name: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayBackDidFinish(noti:)), name: NSNotification.Name.IJKMPMoviePlayerPlaybackDidFinish, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(mediaIsPreparedToPlayDidChange(noti:)), name: NSNotification.Name.IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: self.player)
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayBackStateDidChange(noti:)), name: NSNotification.Name.IJKMPMoviePlayerPlaybackStateDidChange, object: self.player)
    }
    
    @objc func loadStateDidChange(noti: Notification) {
        
        let loadState = self.player?.loadState
        if (loadState!.rawValue & IJKMPMovieLoadState.playthroughOK.rawValue) != 0 {
            print(String(format: "loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK:%d\n",loadState!.rawValue))
        } else if (loadState!.rawValue & IJKMPMovieLoadState.stalled.rawValue) != 0 {
            print("loadStateDidChange: IJKMPMovieLoadStateStalled: \(loadState?.rawValue)\n")
        } else {
            print("loadStateDidChange: ???: \(loadState?.rawValue)\n")
        }
    }
    
    @objc func moviePlayBackDidFinish(noti: Notification) {
        //    MPMovieFinishReasonPlaybackEnded,
        //    MPMovieFinishReasonPlaybackError,
        //    MPMovieFinishReasonUserExited
        let reason1 = noti.userInfo?[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey]
       let reason = reason1!
//        switch reason {
//        case IJKMPMovieFinishReason.playbackEnded:
//            print(String(format: "playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason.rawValue))
//            break
//        case IJKMPMovieFinishReason.userExited:
//        print(String(format: "playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason.rawValue))
//            break
//        case IJKMPMovieFinishReason.playbackError:
//        print(String(format: "playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason.rawValue))
//            break
//        default:
//            print(String(format: "playbackPlayBackDidFinish: ???: %d\n", reason.rawValue))
//            break
//        }
    }
    
    @objc func mediaIsPreparedToPlayDidChange(noti: Notification) {
        print("mediaIsPreparedToPlayDidChange\n")
    }
    
    @objc func moviePlayBackStateDidChange(noti: Notification) {
        //    MPMoviePlaybackStateStopped,
        //    MPMoviePlaybackStatePlaying,
        //    MPMoviePlaybackStatePaused,
        //    MPMoviePlaybackStateInterrupted,
        //    MPMoviePlaybackStateSeekingForward,
        //    MPMoviePlaybackStateSeekingBackward
        if let playbackState = self.player?.playbackState {
            switch playbackState {
            case IJKMPMoviePlaybackState.stopped:
                print(String(format: "IJKMPMoviePlayBackStateDidChange %d: stoped", playbackState.rawValue))
                break
            case IJKMPMoviePlaybackState.playing:
                print(String(format: "IJKMPMoviePlayBackStateDidChange %d: playing", playbackState.rawValue))
                break
            case IJKMPMoviePlaybackState.paused:
                print(String(format: "IJKMPMoviePlayBackStateDidChange %d: paused", playbackState.rawValue))
                break
            case IJKMPMoviePlaybackState.interrupted:
                print(String(format: "IJKMPMoviePlayBackStateDidChange %d: interrupted", playbackState.rawValue))
                break
            case IJKMPMoviePlaybackState.seekingForward,IJKMPMoviePlaybackState.seekingBackward:
                print(String(format: "IJKMPMoviePlayBackStateDidChange %d: seeking", playbackState.rawValue))
                break
                
            default:
                print(String(format: "IJKMPMoviePlayBackStateDidChange %d: unknown", playbackState.rawValue))
                break
            }
        }
        
    }
    
    func removeMovieNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: self.player)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerPlaybackDidFinish, object: self.player)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: self.player)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerPlaybackStateDidChange, object: self.player)
    }
}


