//
//  HTZVideoPlayViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/12.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZVideoPlayViewController: UIViewController {
    
    var videoUrl: String?
    var coverImageUrl: String?
//    {
//        didSet {
//            self.player?.assetURL = URL(string: videoUrl!)!
//            self.controlView.showTitle("title", coverURLString: self.kVideoCover, fullScreenMode: ZFFullScreenMode.landscape)
//        }
//    }
    
    var player: ZFPlayerController?
    
    let kVideoCover = "https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.containerView)
        self.containerView.addSubview(self.playButton)


//        let playerManager = ZFAVPlayerManager()
        let playerManager = ZFIJKPlayerManager()
        /// 播放器相关
        self.player = ZFPlayerController(playerManager: playerManager, containerView: self.containerView)
        self.player?.controlView = self.controlView
        /// 设置退到后台继续播放
        self.player?.pauseWhenAppResignActive = false
        
        weak var weakSelfs = self
        guard let weakSelf = weakSelfs else {
            return
        }
        
        self.player?.orientationWillChange = {(player: ZFPlayerController,  isFullScreen: Bool) in
            weakSelf.setNeedsStatusBarAppearanceUpdate()
        }
        
        /// 播放完成
        self.player?.playerDidToEnd = { asset in
            weakSelf.player?.currentPlayerManager.replay?()
            weakSelf.player?.playTheNext()
            if weakSelf.player?.isLastAssetURL == nil {
                let title = String(format: "视频标题%zd", weakSelf.player?.currentPlayIndex ?? 0)
                weakSelf.controlView.showTitle(title, coverURLString: weakSelf.kVideoCover, fullScreenMode: ZFFullScreenMode.landscape)
            } else {
                weakSelf.player?.stop()
            }
        }
        
        self.player?.assetURL = URL(string: videoUrl!)!
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.player?.isViewControllerDisappear = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        HTZMusicTool.hidePlayBtn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        HTZMusicTool.showPlayBtn()
        self.player?.isViewControllerDisappear = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var x: CGFloat = 0
        var y = self.navigationController?.navigationBar.frame.maxY
        var w: CGFloat = self.view.frame.width
        var h: CGFloat = w*9/16
        self.containerView.frame = CGRect(x: x, y: y!, width: w, height: h)
        
        w = 44
        h = w
        x = (self.containerView.frame.width - w)/2
        y = (self.containerView.frame.height - h)/2
        self.playButton.frame = CGRect(x: x, y: y!, width: w, height: h)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.player?.isFullScreen ?? false {
            return .lightContent
        }
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.player?.isStatusBarHidden ?? false
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var shouldAutorotate: Bool {
        return self.player?.shouldAutorotate ?? false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if self.player?.isFullScreen ?? false {
            return .landscape
        }
        return .portrait
    }

    private func _setupViews() {
        
    }
    
    @objc func playClickAction() {
        self.player?.playTheIndex(0)
        self.controlView.showTitle(title, coverURLString: self.kVideoCover, fullScreenMode: ZFFullScreenMode.landscape)
    }
    
    fileprivate lazy var playButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "new_allPlay_44x44_"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(playClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    fileprivate lazy var controlView: ZFPlayerControlView = {
        let controlView = ZFPlayerControlView()
        controlView.fastViewAnimated = true
        controlView.autoHiddenTimeInterval = 5
        controlView.autoFadeTimeInterval = 0.5
        controlView.prepareShowLoading = true
        controlView.prepareShowControlView = true
        controlView.coverImageView.wb_setImageWith(urlStr: self.coverImageUrl ?? self.kVideoCover)
        return controlView
    }()

    fileprivate lazy var containerView: UIImageView = {
        let imageView = UIImageView()
        imageView.wb_setImage(urlStr: kVideoCover, placeHolderImage: YYRUtilities.image(color: UIColor(red: 220/255.0, green: 220/255.0, blue: 220/255.0, alpha: 1), size: CGSize(width: 1, height: 1)))
        return imageView
    }()
}

