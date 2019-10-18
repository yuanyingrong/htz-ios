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
        
        self.navigationItem.titleView = segmentControl
        
        view.addSubview(tableView)
        
        self.view.addSubview(toDownloadVC.view)
        self.addChild(toDownloadVC)
        toDownloadVC.didMove(toParent: self)
        toDownloadVC.view.isHidden = true
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        toDownloadVC.view.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }
    
    @objc private func segmentedChanged(_ segmented: UISegmentedControl) {
        
        self.toDownloadVC.view.isHidden = segmented.selectedSegmentIndex == 0
        //打印选项的索引
       print("index is \(segmented.selectedSegmentIndex)")
        //打印选择的文字
        print("option is \(String(describing: segmented.titleForSegment(at: segmented.selectedSegmentIndex)))")//将获得值转为String类型
    }
    
    private lazy var toDownloadVC: HTZToDownloadListViewController = {
        let vc = HTZToDownloadListViewController()
        return vc
    }()
    
    private lazy var segmentControl: UISegmentedControl = {
        let items = ["已下载", "下载中"]
        let segmentControl = UISegmentedControl(items: items)
        //设置默认选中的索引,索引从0开始
        segmentControl.selectedSegmentIndex = 0
        //添加监听事件
        segmentControl.addTarget(self, action: #selector(HTZMyDownloadedViewController.segmentedChanged(_:)), for: .valueChanged)
        return segmentControl
    }()
    
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
