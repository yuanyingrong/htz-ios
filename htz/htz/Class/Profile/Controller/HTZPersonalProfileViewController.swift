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
    
    override func configData() {
        super.configData()
        NetWorkRequest(API.getUserInfo) {[weak self] (response) -> (Void) in
            if response["code"].rawString() == "200" {
                if response["data"]["telephone"].stringValue.count > 1 {
                    HTZUserAccount.shared.update(key: "mobile", value: response["data"]["telephone"].stringValue)
                    self?.dataArr[3].rightText = HTZUserAccount.shared.mobile
                }
                if response["data"]["sign"].stringValue.count > 1 {
                    HTZUserAccount.shared.update(key: "sign", value: response["data"]["sign"].stringValue)
                    self?.dataArr[4].rightText = HTZUserAccount.shared.sign
                }
                self?.tableView.reloadData()
            }
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
            if (HTZUserAccount.shared.mobile ?? "") =~ isPhoneNum {
                self.alertConfirmCacellActionAlert(title: "提示", message: "是否修改手机号码？", leftConfirmTitle: "是", rightConfirmTitle: "否", selectLeftBlock: {
                    let vc = HTZBindMobileViewController()
                    vc.bindMoblieSuccessBlock = {
                        self.dataArr[indexPath.row].rightText = HTZUserAccount.shared.mobile
                        self.tableView.reloadData()
                    }
                    self.navigationController?.pushViewController(vc, animated: true)
                }) {
                    
                }
            } else {
                let vc = HTZBindMobileViewController()
                vc.bindMoblieSuccessBlock = {
                    self.dataArr[indexPath.row].rightText = HTZUserAccount.shared.mobile
                    self.tableView.reloadData()
                }
                navigationController?.pushViewController(vc, animated: true)
            }
            
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
                
                let parameters = ["nickname" : HTZUserAccount.shared.nickname,
                                  "unionid" : HTZUserAccount.shared.unionid,
                                  "sign" : text]
                NetWorkRequest(API.updateUserInfo(parameters: parameters as [String : Any])) { (response) -> (Void) in
                    if response["code"].rawString() == "200" {
                        HTZUserAccount.shared.sign = text
                        HTZUserAccount.shared.update(key: "sign", value: text)
                        self?.dataArr[index].rightText = HTZUserAccount.shared.sign
                        self?.tableView.reloadData()
                        if let changeSuccessBlock = self?.changeSuccessBlock {
                            changeSuccessBlock()
                        }
                    }
                }
                
    
            }
            
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
