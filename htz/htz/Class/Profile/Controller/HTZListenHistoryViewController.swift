//
//  HTZListenHistoryViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/20.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZListenHistoryViewController: HTZBaseViewController {
    
    private var dataArr = [HTZListenHistoryModel?]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @objc func deleteAll() {
        NetWorkRequest(API.deleteAllListenHistory, completion: { (response) -> (Void) in
            printLog(response)
            if response["code"].rawString() == "200" {
        
                self.configData()
            }
        }) { (error) -> (Void) in
            
        }
    }
    
    override func configData() {
        NetWorkRequest(API.getListenHistorys(page_index: 0, page_size: 10), completion: { (response) -> (Void) in
            printLog(response)
            if response["code"].rawString() == "200" {
                self.dataArr = [HTZListenHistoryModel].deserialize(from: response["data"].rawString()) ?? []
                self.tableView.reloadData()
            }
        }) { (error) -> (Void) in
            
        }
    }
    
    
    override func configSubView() {
        super.configSubView()
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        view.addSubview(tableView)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
    
    lazy var rightBarButtonItem: UIBarButtonItem = {
        let button = UIButton(title:"清空", target: self, selector: #selector(deleteAll))
//        let button = UIButton(setImage: "delete", setBackgroundImage: "", target: self, action: #selector(deleteAll))
        
        let buttonItem = UIBarButtonItem(customView: button)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        return buttonItem
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZListenHistoryCell.self, forCellReuseIdentifier: "HTZListenHistoryCellReuseID")
        return tableView
    }()
    
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZListenHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZListenHistoryCellReuseID", for: indexPath) as! HTZListenHistoryCell
        cell.delegate = self
        cell.listenHistoryModel = dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//        let vc = HTZMyFavoriteAlbumViewController()
//        navigationController?.pushViewController(vc, animated: true)
        
    }
}

extension HTZListenHistoryViewController : HTZListenHistoryCellDelegate {
    
    @objc func deleteAction(_ cell: HTZListenHistoryCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        let model = self.dataArr[(indexPath?.row)!]
        if let model = model, let id = model.id {
            NetWorkRequest(API.deleteListenHistory(id: id), completion: { (response) -> (Void) in
                printLog(response)
                if response["code"].rawString() == "200" {
            
                    self.configData()
                }
            }) { (error) -> (Void) in
                
            }
        }
        
    }
}
