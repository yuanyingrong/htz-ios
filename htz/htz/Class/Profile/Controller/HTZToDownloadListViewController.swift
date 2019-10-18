//
//  HTZToDownloadListViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/18.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZToDownloadListViewController: HTZBaseViewController {
    
    private var dataArr = [HTZDownloadModel]()
    
    var index: NSInteger = 0
    var albumId: String?
    
    private var albumIcon: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        kDownloadManager.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.requestData()
        
        kDownloadManager.startdownloadRequest()
      }
    
    private func requestData() {
        
        dataArr = kDownloadManager.toDownloadFileList()
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
        tableView.register(HTZToDownloadListCell.self, forCellReuseIdentifier: "HTZToDownloadListCellReuseID")
        return tableView
    }()
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZToDownloadListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZToDownloadListCellReuseID", for: indexPath) as! HTZToDownloadListCell
        cell.delegate = self
        cell.imageName = albumIcon
        cell.downloadModel = self.dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

// MARK: - HTZDownloadManagerDelegate
extension HTZToDownloadListViewController: HTZDownloadManagerDelegate {
    @objc func downloadChanged(_ downloadManager: HTZDownloadManager, downloadModel: HTZDownloadModel, state: HTZDownloadManagerState) {
        
        for model in self.dataArr {
            // 下载的是当前播放的
            if model.fileID == downloadModel.fileID {
                if state == HTZDownloadManagerState.finished { // 下载完成
                    DispatchQueue.main.async {
                        // 改变状态
                        self.requestData()
                    }
                }
            }
        }
        
    }
    
    
    @objc func removedDownloadArr(_ downloadManager: HTZDownloadManager, downloadArr: [HTZDownloadModel]) {
        
    }
    
    @objc func downloadProgress(_ downloadManager: HTZDownloadManager, downloadModel: HTZDownloadModel, totalSize: NSInteger, downloadSize: NSInteger, progress: Float) {
        print(progress)
        for (idx, model) in self.dataArr.enumerated() {
            // 下载的是当前播放的
            if model.fileID == downloadModel.fileID {
                let cell = self.tableView.cellForRow(at: IndexPath(row: idx, section: 0))  as! HTZToDownloadListCell
                model.fileSize = downloadManager.convertFromByteNum(b: CUnsignedLongLong(totalSize))
                model.fileCurrentSize = downloadManager.convertFromByteNum(b: CUnsignedLongLong(downloadSize))
                cell.downloadModel = model
            }
        }
    }
    
}


// MARK: - HTZToDownloadListCellDelegate
extension HTZToDownloadListViewController: HTZToDownloadListCellDelegate {
    
    @objc func deleteAction(_ cell: HTZToDownloadListCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        let model = self.dataArr[(indexPath?.row)!]
       
        alertConfirmCacellActionAlert(title: "提示", message: "是否删除下载： \(model.fileName)", leftConfirmTitle: "删除", rightConfirmTitle: "取消", selectLeftBlock: {
            
            kDownloadManager.deleteDownloadModelArr(modelArr: [model])
            if self.dataArr.count == 1 {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.requestData()
            }
        }, selectRightBlock: nil)
        
       
    }
}
