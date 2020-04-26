//
//  HTZSettingViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/26.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

struct SettingCell {
    
    var title: String?
    var rightText: String?
}

class HTZSettingViewController: HTZBaseViewController {
    
    let dataArr: [SettingCell] = {
            let dataArr = [SettingCell(title: "关于我们", rightText: ""),SettingCell(title: "清除缓存", rightText: "M")]
            return dataArr
        }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
extension HTZSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        var cell =  tableView.dequeueReusableCell(withIdentifier: "HTZMyNotificationCellReuseID", for: indexPath)
        var cell =  tableView.dequeueReusableCell(withIdentifier: "HTZSettingCellReuseID")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HTZSettingCellReuseID")
            let line = UIView()
            line.backgroundColor = .groupTableViewBackground
            cell?.contentView.addSubview(line)
            
            line.snp.makeConstraints { (make) in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(1)
            }
        }
        cell?.accessoryType = .disclosureIndicator
        cell?.textLabel?.text = dataArr[indexPath.row].title
        cell?.detailTextLabel?.text = dataArr[indexPath.row].rightText
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//        let vc = HTZMyNotificationDetailViewController()
//        vc.title = dataArr[indexPath.row]?.title
//        vc.content = dataArr[indexPath.row]?.msg
//        navigationController?.pushViewController(vc, animated: true)
        if indexPath.row == 1 {
            
        }
        
    }
}
