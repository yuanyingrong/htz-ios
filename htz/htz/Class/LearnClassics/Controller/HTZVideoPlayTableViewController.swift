//
//  HTZVideoPlayTableViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/16.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZVideoPlayTableViewController: UIViewController {
    
//    var videoUrl: String?
//    var coverImageUrl: String?
    var dataSource: [HTZVideoModel?]?
    var urls: [URL] = []
//    {
//        didSet {
//            self.player?.assetURL = URL(string: videoUrl!)!
//            self.controlView.showTitle("title", coverURLString: self.kVideoCover, fullScreenMode: ZFFullScreenMode.landscape)
//        }
//    }
    
    var player: ZFPlayerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.view.addSubview(self.tableView)

        self.requestData()

//        let playerManager = ZFAVPlayerManager()
        let playerManager = ZFIJKPlayerManager()
        /// player的tag值必须在cell里设置
        self.player = ZFPlayerController(scrollView: self.tableView, playerManager: playerManager, containerViewTag: 100)
        self.player?.controlView = self.controlView
        self.player?.assetURLs = self.urls
        self.player?.shouldAutoPlay = false
        /// 1.0是完全消失的时候
        self.player?.playerDisapperaPercent = 1.0
        /// 设置退到后台继续播放
//        self.player?.pauseWhenAppResignActive = false
        
        weak var weakSelfs = self
        guard let weakSelf = weakSelfs else {
            return
        }
        
        self.player?.orientationWillChange = {(player: ZFPlayerController,  isFullScreen: Bool) in
            weakSelf.setNeedsStatusBarAppearanceUpdate()
            UIViewController.attemptRotationToDeviceOrientation()
            self.tableView.scrollsToTop = !isFullScreen
        }
        
        /// 播放完成
        self.player?.playerDidToEnd = { asset in
//            if weakSelf.player?.playingIndexPath?.row ?? 0 < (weakSelf.urls?.count ?? 0) - 1 && !(weakSelf.player?.isFullScreen ?? false) {
//                let indexPath = NSIndexPath(row: (weakSelf.player?.playingIndexPath?.row ?? 0)+1, section: 0)
////                [self playTheVideoAtIndexPath:indexPath scrollToTop:YES]
//            } else if weakSelf.player!.isFullScreen {
//                weakSelf.player?.stopCurrentPlayingCell()
//            }
            weakSelf.player?.stopCurrentPlayingCell()
        }
    
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let y = self.navigationController?.navigationBar.frame.maxY
        let h = self.view.frame.maxY
        self.tableView.frame = CGRect(x: 0, y: y!, width: self.view.frame.size.width, height: h-y!)
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
        if self.player?.isFullScreen ?? false && self.player?.orientationObserver.fullScreenMode == ZFFullScreenMode.landscape {
            return .landscape
        }
        return .portrait
    }

    private lazy var controlView: ZFPlayerControlView = {
        let controlView = ZFPlayerControlView()
//        controlView.fastViewAnimated = true
//        controlView.autoHiddenTimeInterval = 5
//        controlView.autoFadeTimeInterval = 0.5
        controlView.prepareShowLoading = true
//        controlView.prepareShowControlView = true
//        controlView.coverImageView.wb_setImageWith(urlStr: self.coverImageUrl ?? self.kVideoCover)
        return controlView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZVideoPlayCell.self, forCellReuseIdentifier: "HTZVideoPlayCellReuseID")
        return tableView
    }()
}
// MARK: - UIScrollViewDelegate  列表播放必须实现
extension HTZVideoPlayTableViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidEndDecelerating()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollView.zf_scrollViewDidEndDraggingWillDecelerate(decelerate)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidScrollToTop()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidScroll()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewWillBeginDragging()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZVideoPlayTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZVideoPlayCellReuseID", for: indexPath) as! HTZVideoPlayCell
        
        cell.setDelegate(delegate: self, indexPath: indexPath)
        cell.videoModel = self.dataSource![indexPath.row]
        cell.setNormalMode()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// 如果正在播放的index和当前点击的index不同，则停止当前播放的index
        if self.player?.playingIndexPath == indexPath {
            self.player?.stopCurrentPlayingCell()
        }
        /// 如果没有播放，则点击进详情页会自动播放
        if !(self.player?.currentPlayerManager.isPlaying)! {
            
        }
    }
    
}

// MARK: - HTZVideoPlayCellDelegate
extension HTZVideoPlayTableViewController: HTZVideoPlayCellDelegate {
    
    @objc internal func palyTheVideoAt(_ indexPath: IndexPath) {
        self.palyTheVideoAt(indexPath, scrollToTop: false)
    }
}

// MARK: - private method
extension HTZVideoPlayTableViewController {
    
    private func palyTheVideoAt(_ indexPath: IndexPath, scrollToTop: Bool) {
        self.player?.playTheIndexPath(indexPath, scrollToTop: scrollToTop)
        let model = self.dataSource![indexPath.row]
        self.controlView.showTitle(model?.title, coverURLString: model?.coverUrl, fullScreenMode: .landscape)
    }
    
    private func requestData() {
        let target = API.mixinxiaoshipin
        NetWorkRequest(target) { (response) -> (Void) in
            let videos = [HTZVideoModel].deserialize(from: response["videos"].rawString())
            if let videos = videos {
                for model in videos {
                    model?.videoUrl = "http://htzshanghai.top/resources/videos/" + model!.videoUrl!
                    model?.coverUrl = "http://htzshanghai.top/resources/videos/" + model!.coverUrl!
                    var charSet = CharacterSet.urlQueryAllowed
                    charSet.insert(charactersIn: "#")
                    let urlStr = model?.videoUrl?.addingPercentEncoding(withAllowedCharacters: charSet)
                    let url = URL(string: urlStr!)
                    self.urls.append(url!)
                }
                self.player?.assetURLs = self.urls
                self.dataSource = videos
                self.tableView.reloadData()
            }
        }
    }
}
