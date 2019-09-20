//
//  HTZMyDownloadedViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/18.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZMyDownloadedAlbumViewController: HTZBaseViewController {
    
    private var dataArr = [HTZMusicModel?]()
    
    var index: NSInteger = 0
    
    private var albumIcon: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func configData() {
        super.configData()
        
        dataArr.removeAll()
        for obj in kDownloadManager.downloadedFileList() {
            let musicModel = HTZMusicModel()
            musicModel.song_id = obj.fileID
            musicModel.song_name = obj.fileName
            musicModel.file_link = obj.fileUrl
            musicModel.file_duration = obj.fileDuration
            musicModel.lrclink = obj.fileLyric
            
            dataArr.append(musicModel)
        }
        
        self.tableView.reloadData()
    }
    
    override func configSubView() {
        super.configSubView()
        
        view.addSubview(tableView)
    }
    
    
    override func configConstraint() {
        super.configConstraint()
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZMyDownloadedAlbumCell.self, forCellReuseIdentifier: "HTZMyDownloadedAlbumCellReuseID")
        return tableView
    }()
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMyDownloadedAlbumViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyDownloadedAlbumCellReuseID", for: indexPath) as! HTZMyDownloadedAlbumCell
        cell.delegate = self
//        cell.imageName = albumModel?.icon
        cell.musicModel = self.dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = HTZPlayViewController.sharedInstance
        //        let music = HTZMusicModel()
        //        music.fileName = self.dataArr[indexPath.row]?.audio
        //        music.lrcName = self.dataArr[indexPath.row]?.lyric
        //        music.name = self.dataArr[indexPath.row]?.title
        //        music.icon = "chuan_xi_lu"
        //        music.singer = "dddd"
        //        music.singerIcon = "chuan_xi_lu"
        vc.title = self.dataArr[indexPath.row]?.album_title
        vc.setPlayerList(playList: dataArr as! [HTZMusicModel])
        vc.playMusic(index: indexPath.row, isSetList: true)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
}

// MARK: - HTZMyDownloadedAlbumCellDelegate
extension HTZMyDownloadedAlbumViewController: HTZMyDownloadedAlbumCellDelegate {
    
    @objc func deleteAction(_ cell: HTZMyDownloadedAlbumCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        let model = HTZDownloadModel()
        model.fileID = self.dataArr[(indexPath?.row)!]!.song_id
        kDownloadManager.deleteDownloadModelArr(modelArr: [model])
        
        self.configData()
    }

    
}
