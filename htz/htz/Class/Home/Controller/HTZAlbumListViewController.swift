//
//  HTZAlbumListViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/2.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import Alamofire

class HTZAlbumListViewController: HTZBaseViewController {
    
    private lazy var albumListViewModel: HTZAlbumListViewModel = HTZAlbumListViewModel()
    
    var albumModel: HTZAlbumModel? {
    
        didSet {
            if let albumModel = albumModel {
                nameLabel.text = albumModel.title
                if albumModel.icon!.hasPrefix("http") {
                    albumImageView.wb_setImageWith(urlStr: albumModel.icon!)
                } else {
                    albumImageView.image = UIImage(named: albumModel.icon ?? "")
                }
                contentLabel.text = albumModel.desc
                countLabel.text = "共\(albumModel.item_total ?? "0")集"
                
                albumListViewModel.icon = albumModel.icon
                albumListViewModel.albumTitle = albumModel.title
                
                albumListViewModel.requestData(index: albumModel.index!, isPullDown: true) { (success) in
                    if success {
                        self.countLabel.text = "共\(self.albumListViewModel.dataArr.count)集"
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    private let albumImageView = UIImageView()
    
    private let nameLabel = UILabel(title: "", fontSize: 16, textColor: UIColor.darkText, alignMent: NSTextAlignment.center, numOfLines: 0)
    
    private let contentLabel = UILabel(title: "", fontSize: 14, textColor: UIColor.darkGray, alignMent: NSTextAlignment.center, numOfLines: 0)
    
    private lazy var onlineListeningButton: UIButton = {
        let onlineListeningButton = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        onlineListeningButton.set(image: UIImage(named: "地图"), title: "在线收听", titlePosition: UIView.ContentMode.right , additionalSpacing: 4, state: UIControl.State.normal)
        onlineListeningButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        onlineListeningButton.layer.borderColor = UIColor.red.cgColor
        onlineListeningButton.layer.borderWidth = 2
        onlineListeningButton.addTarget(self, action: #selector(onlineListeningButtonClickAction), for: UIControl.Event.touchUpInside)
        return onlineListeningButton
    }()
    
    private lazy var cacheDownloadButton: UIButton = {
        let cacheDownloadButton = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        cacheDownloadButton.set(image: UIImage(named: "地图"), title: "缓存下载", titlePosition: UIView.ContentMode.right , additionalSpacing: 4, state: UIControl.State.normal)
        cacheDownloadButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        cacheDownloadButton.layer.borderColor = UIColor.red.cgColor
        cacheDownloadButton.layer.borderWidth = 2
        cacheDownloadButton.addTarget(self, action: #selector(cacheDownloadButtonClickAction), for: UIControl.Event.touchUpInside)
        return cacheDownloadButton
    }()
    
    private lazy var middleLine: UIView = {
        let middleLine = UIView()
        middleLine.backgroundColor = UIColor.groupTableViewBackground
        return middleLine
    }()
    
    private let countLabel = UILabel(title: "共30集", fontSize: 16, textColor: UIColor.darkText, alignMent: NSTextAlignment.center, numOfLines: 0)
    
    private lazy var middleSecondLine: UIView = {
        let middleLine = UIView()
        middleLine.backgroundColor = UIColor.groupTableViewBackground
        return middleLine
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZAlbumListCell.self, forCellReuseIdentifier: "HTZAlbumListCellReuseID")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

       self.view.backgroundColor = UIColor.white
        kDownloadManager.delegate = self
    }
    
    override func configSubView() {
        super.configSubView()
        initUI()
        initConstraint()
    }
    
    override func configData() {
        super.configData()
        
//        albumListViewModel.requestSongData(isPullDown: true) { (sucess) in
//            
//        }
    }

}

// MARK: 按钮点击事件
extension HTZAlbumListViewController {
    
    // 在线收听
    @objc private func onlineListeningButtonClickAction() {
        print("在线收听")
    }
    
    // 缓存下载
    @objc private func cacheDownloadButtonClickAction() {
        print("缓存下载")
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZAlbumListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumListViewModel.dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZAlbumListCellReuseID", for: indexPath) as! HTZAlbumListCell
        cell.delegate = self
        cell.imageName = albumModel?.icon
        if let imageName = self.albumListViewModel.dataSongArr[indexPath.row]?.icon {
            cell.imageName = imageName
        }
        self.albumListViewModel.dataArr[indexPath.row]?.isVideo = albumModel?.isVideo
        cell.albumPartModel = self.albumListViewModel.dataArr[indexPath.row]
        cell.musicModel = self.albumListViewModel.dataSongArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        if let isVideo = albumModel!.isVideo, isVideo {
            let vc = HTZVideoPlayViewController()
            vc.videoUrl = self.albumListViewModel.dataSongArr[indexPath.row]!.file_link
            vc.coverImageUrl = self.albumListViewModel.dataSongArr[indexPath.row]!.icon
            vc.title = self.albumListViewModel.dataSongArr[indexPath.row]?.album_title
            navigationController?.pushViewController(vc, animated: true)
//            let nav = UINavigationController(rootViewController: vc)
//            nav.modalPresentationStyle = .fullScreen
//            self.present(nav, animated: true, completion: nil)
        } else {
            let vc = HTZPlayViewController.sharedInstance
            //        let music = HTZMusicModel()
            //        music.fileName = self.albumListViewModel.dataArr[indexPath.row]?.audio
            //        music.lrcName = self.albumListViewModel.dataArr[indexPath.row]?.lyric
            //        music.name = self.albumListViewModel.dataArr[indexPath.row]?.title
            //        music.icon = "chuan_xi_lu"
            //        music.singer = "dddd"
            //        music.singerIcon = "chuan_xi_lu"
                    vc.title = self.albumListViewModel.dataSongArr[indexPath.row]?.album_title
                    vc.setPlayerList(playList: self.albumListViewModel.dataSongArr as! [HTZMusicModel])
                    vc.playMusic(index: indexPath.row, isSetList: true)
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
        }
        
        
    }
    
}

// MARK: - HTZAlbumListCellDelegate
extension HTZAlbumListViewController: HTZAlbumListCellDelegate {
    
    @objc func downloadButtonClickAction(_ cell: HTZAlbumListCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        let model = self.albumListViewModel.dataSongArr[indexPath!.row]
        if let model = model, let downloadState = model.downloadState {
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
                self.alertConfirmCacellActionAlert(title: "", message: "该歌曲已下载，是否删除下载问题", leftConfirmTitle: "删除", rightConfirmTitle: "取消", selectLeftBlock: {
                    let dModel = HTZDownloadModel()
                    dModel.fileID = model.song_id
                    dModel.fileAlbumId = model.album_id
                    kDownloadManager.deleteDownloadModelArr(modelArr: [dModel])
                }, selectRightBlock: nil)
                break
            
            }
        }
        self.tableView.reloadData()
    }
}
// MARK: HTZDownloadManagerDelegate
extension HTZAlbumListViewController: HTZDownloadManagerDelegate {
    func downloadChanged(_ downloadManager: HTZDownloadManager, downloadModel: HTZDownloadModel, state: HTZDownloadManagerState) {
        if state == HTZDownloadManagerState.finished {
           
            albumListViewModel.requestData(index: albumModel!.index!, isPullDown: true) { (success) in
                if success {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func removedDownloadArr(_ downloadManager: HTZDownloadManager, downloadArr: [HTZDownloadModel]) {
        
    }
    
    func downloadProgress(_ downloadManager: HTZDownloadManager, downloadModel: HTZDownloadModel, totalSize: NSInteger, downloadSize: NSInteger, progress: Float) {
        
    }
    
    
}

// MARK: - UI
extension HTZAlbumListViewController {
    
     func initUI() {
        
        view.addSubview(albumImageView)
        view.addSubview(nameLabel)
        view.addSubview(contentLabel)
        view.addSubview(onlineListeningButton)
        view.addSubview(cacheDownloadButton)
        view.addSubview(middleLine)
        view.addSubview(countLabel)
        view.addSubview(middleSecondLine)
        view.addSubview(tableView)
    }
    
    func initConstraint() {
        
        albumImageView.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide).offset(3 * kGlobelMargin)
            } else {
                make.top.equalTo(view).offset(2 * kGlobelMargin)
            }
            make.left.equalTo(view).offset(2 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 112, height: 122))
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(albumImageView)
            make.left.equalTo(albumImageView.snp.right).offset((kScreenWidth - 170)/2)
        }
        
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo((nameLabel.snp.bottom))
            make.left.equalTo(albumImageView.snp.right).offset(kGlobelMargin * 0.5)
            make.bottom.equalTo(albumImageView).offset(2 * kGlobelMargin)
            make.right.equalTo(view).offset(-2 * kGlobelMargin)
        }
        
        onlineListeningButton.snp.makeConstraints { (make) in
            make.top.equalTo(albumImageView.snp.bottom).offset(3 * kGlobelMargin)
            make.left.equalTo(view).offset(3 * kGlobelMargin)
            make.right.equalTo(view.snp.centerX).offset(-kGlobelMargin)
            make.height.equalTo(36)
        }
        
        cacheDownloadButton.snp.makeConstraints { (make) in
            make.top.height.equalTo(onlineListeningButton)
            make.left.equalTo(view.snp.centerX).offset(kGlobelMargin)
            make.right.equalTo(view).offset(-3 * kGlobelMargin)
        }
        
        middleLine.snp.makeConstraints { (make) in
            make.top.equalTo(onlineListeningButton.snp.bottom).offset(2 * kGlobelMargin)
            make.left.right.equalTo(view)
            make.height.equalTo(4)
        }
        
        countLabel.snp.makeConstraints { (make) in
            make.top.equalTo(middleLine.snp.bottom).offset(2 * kGlobelMargin)
            make.left.equalTo(view).offset(4 * kGlobelMargin)
        }
        
        middleSecondLine.snp.makeConstraints { (make) in
            make.top.equalTo(countLabel.snp.bottom).offset(2 * kGlobelMargin)
            make.left.right.equalTo(view)
            make.height.equalTo(1)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(middleSecondLine.snp.bottom)
            make.left.right.equalTo(view)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            } else {
                make.bottom.equalTo(view)
            }
        }
    }

}
