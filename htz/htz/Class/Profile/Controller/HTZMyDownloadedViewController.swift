//
//  HTZMyDownloadedViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/20.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZMyDownloadedViewController: HTZBaseViewController {
    
    private var dataArr: [HTZSaveDataModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.requestData()
    }
    
    private func requestData() {
        dataArr = kDownloadManager.downloadedFileList()
        
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
        tableView.register(HTZMyDownloadedCell.self, forCellReuseIdentifier: "HTZMyDownloadedCellReuseID")
        return tableView
    }()
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMyDownloadedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyDownloadedCellReuseID", for: indexPath) as! HTZMyDownloadedCell
        cell.delegate = self
        cell.saveDataModel = dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = HTZMyDownloadedAlbumViewController()
        vc.title = dataArr[indexPath.row].albumTitle
        vc.albumId = dataArr[indexPath.row].albumID
        vc.index = indexPath.row
        navigationController?.pushViewController(vc, animated: true)
        
    }
}

// MARK: - HTZMyDownloadedCellDelegate
extension HTZMyDownloadedViewController: HTZMyDownloadedCellDelegate {
    @objc func deleteAction(_ cell: HTZMyDownloadedCell) {
        
        let indexPath = self.tableView.indexPath(for: cell)
        let model = self.dataArr[indexPath!.row]
        
        alertConfirmCacellActionAlert(title: "提示", message: "是否删除专辑：\(model.albumTitle!)", leftConfirmTitle: "删除", rightConfirmTitle: "取消", selectLeftBlock: {
            
            kDownloadManager.deleteDownloadedAlbum(albumId: model.albumID!)
            self.requestData()
        }, selectRightBlock: nil)
        
    }
    
}
