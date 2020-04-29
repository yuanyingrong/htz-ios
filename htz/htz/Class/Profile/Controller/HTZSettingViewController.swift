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
    
    var dataArr: [SettingCell] = {
            let dataArr = [SettingCell(title: "关于我们", rightText: ""),SettingCell(title: "清除缓存", rightText: "M")]
            return dataArr
        }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZPersonalProfileShowTableViewCell.self, forCellReuseIdentifier: "HTZSettingCellReuseID")
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
        
        dataArr[1].rightText = getCacheSize()
        tableView.reloadData()
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }
    
    ///获取APP缓存
    func getCacheSize()-> String {

        // 取出cache文件夹目录
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first

        // 取出文件夹下所有文件数组
        let fileArr = FileManager.default.subpaths(atPath: cachePath!)

        //快速枚举出所有文件名 计算文件大小
        var size = 0
        for file in fileArr! {

            // 把文件名拼接到路径中
            let path = cachePath! + ("/\(file)")
            // 取出文件属性
            let floder = try! FileManager.default.attributesOfItem(atPath: path)
            // 用元组取出文件大小属性
            for (key, fileSize) in floder {
                // 累加文件大小
                if key == FileAttributeKey.size {
                    size += (fileSize as AnyObject).integerValue
                }
            }
        }

        let totalCache = Double(size) / 1024.00 / 1024.00
        return String(format: "%.2f M", totalCache)
    }
    
    ///删除APP缓存
    func clearCache() {
        // 取出cache文件夹目录
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        
        let fileArr = FileManager.default.subpaths(atPath: cachePath!)
        
        // 遍历删除
        
        for file in fileArr! {
            
            let path = (cachePath! as NSString).appending("/\(file)")
            
            if FileManager.default.fileExists(atPath: path) {
                
                do {
                    
                    try FileManager.default.removeItem(atPath: path)
                    
                } catch {
                    
                }
            }
            
        }
    }
    
    
}


// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZSettingCellReuseID", for: indexPath) as! HTZPersonalProfileShowTableViewCell
        cell.leftStr = dataArr[indexPath.row].title
        cell.rightStr = dataArr[indexPath.row].rightText
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//        let vc = HTZMyNotificationDetailViewController()
//        vc.title = dataArr[indexPath.row]?.title
//        vc.content = dataArr[indexPath.row]?.msg
//        navigationController?.pushViewController(vc, animated: true)
        if indexPath.row == 1 {
            self.clearCache()
            self.alert(message: "清理完毕！")
            dataArr[1].rightText = getCacheSize()
            tableView.reloadData()
        }
    }
}
