//
//  HTZVideoPlayFullViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZVideoPlayFullViewController: HTZBaseViewController {
    
    
    var player: IJKFFMoviePlayerController?
    
    var urlStr: String
    
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

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.rotate = 1
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.rotate = 0
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
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
        
        self.player?.view.frame = self.view.bounds
        self.player?.scalingMode = .aspectFit
        self.player?.shouldAutoplay = true
        self.view.autoresizesSubviews = true
        self.view.addSubview((self.player?.view)!)
        
        self.view.addSubview(self.slider)
        
    }
    
    override var shouldAutorotate: Bool {
        get {
            return true
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
    
    func forceSetOrientation(_ orientation: UIInterfaceOrientation) {
        if orientation == .unknown {
            
        }
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let duration: TimeInterval = coordinator.transitionDuration
        if size.width > size.height {
//            horiz
        } else {
            
        }
    }
    
    override func configConstraint() {
        super.configConstraint()
        weak var weakSelf = self
        self.slider.snp.makeConstraints { (make) in
            make.left.right.equalTo(weakSelf!.view)
            make.top.equalTo((weakSelf?.player?.view.snp.bottom)!)
        }
        
//        playButton.snp.makeConstraints { (make) in
//            make.center.equalTo(weakSelf!.view)
//        }
    }
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "stop"), for: UIControl.State.highlighted)
        button.addTarget(self, action: #selector(playOrPause), for: UIControl.Event.touchUpInside)
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
extension HTZVideoPlayFullViewController: HTZSliderViewDelegate {
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
extension HTZVideoPlayFullViewController {
    
    @objc private func playOrPause() {
        if (self.player?.isPlaying())! {
            self.player?.pause()
        } else {
            self.player?.play()
        }
    }
}
/// 通知
extension HTZVideoPlayFullViewController {
    
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

