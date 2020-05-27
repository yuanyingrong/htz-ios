//
//  HTZPersonalProfileViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/26.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit
import ZWAlertController

class HTZPersonalProfileViewController: HTZBaseViewController {
    
    var changeSuccessBlock: (()->())?
    
    var dataArr: [SettingCell] = {
        
        let dataArr = [SettingCell(title: "头像", rightText: HTZUserAccount.shared.headimgurl),SettingCell(title: "地区", rightText: "\(HTZUserAccount.shared.province ?? "") \(HTZUserAccount.shared.city ?? "")"),SettingCell(title: "性别", rightText: HTZUserAccount.shared.gender),SettingCell(title: "电话", rightText: HTZUserAccount.shared.mobile),SettingCell(title: "昵称", rightText: HTZUserAccount.shared.name)]
            return dataArr
        }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZPersonalProfilePortraitCell.self, forCellReuseIdentifier: "HTZPersonalProfilePortraitCellReuseID")
        tableView.register(HTZPersonalProfileShowTableViewCell.self, forCellReuseIdentifier: "HTZPersonalProfileShowTableViewCellReuseID")
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
            make.top.equalTo(view.snp.topMargin).offset(kGlobelMargin)
            make.left.right.bottom.equalTo(view)
        }
    }
    
    
}


// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZPersonalProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0 {
            let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZPersonalProfilePortraitCellReuseID", for: indexPath) as! HTZPersonalProfilePortraitCell
            cell.leftStr = dataArr[indexPath.row].title
            cell.portraitImage = dataArr[indexPath.row].rightText
            return cell
        } else {
            let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZPersonalProfileShowTableViewCellReuseID", for: indexPath) as! HTZPersonalProfileShowTableViewCell
            cell.leftStr = dataArr[indexPath.row].title
            cell.rightStr = dataArr[indexPath.row].rightText
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 { // 头像查看
            
        } else if indexPath.row == 3 { // 电话
            let vc = HTZBindMobileViewController()
            vc.bindMoblieSuccessBlock = {
                
            }
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 4 { // 昵称
            showTextEntryAlert(index: indexPath.row, title: "请输入您的昵称")
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func showTextEntryAlert(index: NSInteger, title: String) {
        let title = title
        let message = ""
        let cancelButtonTitle = "取消"
        let confirmButtonTitle = "确定"
        
        let alertController = ZWAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.textLimit = 30  // == 限制10个中文字符 limit 10 Chinese characters, equal to 30 English characters
        // Add the text field for text entry.
        alertController.addTextFieldWithConfigurationHandler { textField in
            // If you need to customize the text field, you can ZW so here.
            
        }
        
        // Create the actions.
        let cancelAction = ZWAlertAction(title: cancelButtonTitle, style: .cancel) { action in
            NSLog("The \"Text Entry\" alert's cancel action occured.")
        }
        
        let otherAction = ZWAlertAction(title: confirmButtonTitle, style: .default) {[weak self] action in
            NSLog("The \"Text Entry\" alert's other action occured.")
            let text = (alertController.textFields![0] as! ZWTextField).text
            if let text = text, text.length > 0 {
                HTZUserAccount.shared.name = text
                HTZUserAccount.shared.update(key: "name", value: text)
                if let changeSuccessBlock = self?.changeSuccessBlock {
                    changeSuccessBlock()
                }
                
                self?.dataArr[index].rightText = HTZUserAccount.shared.name
                self?.tableView.reloadData()
    
            }
            
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
