//
//  HTZMyFavoriteListViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/20.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZMyFavoriteViewController: HTZBaseViewController {
    
    private var dataArr: [HTZSaveDataModel] = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZMyFavoriteCell.self, forCellReuseIdentifier: "HTZMyFavoriteCellReuseID")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dataArr = HTZMusicTool.lovedMusicList() ?? []
        
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
    
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMyFavoriteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyFavoriteCellReuseID", for: indexPath) as! HTZMyFavoriteCell
        cell.delegate = self
        cell.saveDataModel = dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = HTZMyFavoriteAlbumViewController()
        vc.title = dataArr[indexPath.row].albumTitle
        vc.index = indexPath.row
        navigationController?.pushViewController(vc, animated: true)
        
    }
}

// MARK: - HTZMyFavoriteCellDelegate
extension HTZMyFavoriteViewController: HTZMyFavoriteCellDelegate {
    @objc func deleteAction(_ cell: HTZMyFavoriteCell) {
//        let indexPath = self.tableView.indexPath(for: cell)
//        let model = HTZDownloadModel()
//        model.fileID = self.dataArr[(indexPath?.row)!]!.song_id
//        kDownloadManager.deleteDownloadModelArr(modelArr: [model])
        
        self.configData()
    }

}
