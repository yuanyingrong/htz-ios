//
//  HTZMyNotificationViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/20.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZMyNotificationViewController: HTZBaseViewController {
    
    private var dataArr = [HTZNotificationsModel?]()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HTZMyNotificationCellReuseID")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NetWorkRequest(API.notifications(page_index: 0, page_size: 10), completion: { (response) -> (Void) in
            printLog(response)
            if response["code"].rawString() == "200" {
                self.dataArr = [HTZNotificationsModel].deserialize(from: response["data"].rawString()) ?? []
                self.tableView.reloadData()
            }
        }) { (error) -> (Void) in
            
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
extension HTZMyNotificationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        var cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyNotificationCellReuseID", for: indexPath)
        var cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyNotificationCellReuseID")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HTZMyNotificationCellReuseID")
        }
        cell?.textLabel?.text = dataArr[indexPath.row]?.title
        cell?.detailTextLabel?.text = dataArr[indexPath.row]?.msg
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = HTZMyFavoriteAlbumViewController()
//        vc.title = dataArr[indexPath.row].albumTitle
        vc.index = indexPath.row
        navigationController?.pushViewController(vc, animated: true)
        
    }
}
