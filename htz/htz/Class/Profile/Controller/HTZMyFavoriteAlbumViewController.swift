//
//  HTZMyFavoriteViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/18.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZMyFavoriteAlbumViewController: HTZBaseViewController {
    
    private var dataArr: [HTZMusicModel] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var index: NSInteger = 0
    
    private var albumIcon: String = ""
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZMyFavoriteAlbumCell.self, forCellReuseIdentifier: "HTZMyFavoriteAlbumCellReuseID")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let arr = HTZMusicTool.lovedMusicList() {
            dataArr = arr.count > index ? arr[index].files ?? [] : []
            albumIcon = arr.count > index ? arr[index].albumIcon ?? "" : ""
        }
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
  

}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMyFavoriteAlbumViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyFavoriteAlbumCellReuseID", for: indexPath) as! HTZMyFavoriteAlbumCell
        cell.imageName = albumIcon
        cell.musicModel = dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = HTZPlayViewController.sharedInstance
        //        let music = HTZMusicModel()
        //        music.fileName = self.albumListViewModel.dataArr[indexPath.row]?.audio
        //        music.lrcName = self.albumListViewModel.dataArr[indexPath.row]?.lyric
        //        music.name = self.albumListViewModel.dataArr[indexPath.row]?.title
        //        music.icon = "chuan_xi_lu"
        //        music.singer = "dddd"
        //        music.singerIcon = "chuan_xi_lu"
        vc.title = dataArr[indexPath.row].album_title
        vc.setPlayerList(playList: dataArr )
        vc.playMusic(index: indexPath.row, isSetList: true)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
