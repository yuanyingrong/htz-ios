//
//  HTZProfileViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

struct ProfileCell {
    
    var imageName: String?
    var title: String?
    
}

class HTZProfileViewController: HTZBaseViewController {

    let dataArr: [ProfileCell] = {
        let dataArr = [ProfileCell(imageName: "favorite", title: "我的收藏"),ProfileCell(imageName: "history", title: "播放历史"), ProfileCell(imageName: "item_list", title: "我的通知"), ProfileCell(imageName: "item_list", title: "设置")]
//        let dataArr = [ProfileCell(imageName: "favorite", title: "我的消息"), ProfileCell(imageName: "history", title: "我的收藏"), ProfileCell(imageName: "favorite", title: "我的设置"), ProfileCell(imageName: "history", title: "我的赞赏"), ProfileCell(imageName: "history", title: "我的意见反馈")]
        return dataArr
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(HTZProfileTableViewCell.self, forCellReuseIdentifier: "HTZProfileTableViewCellReuseID")
        return tableView
    }()
    
    lazy var headerView: HTZProfileHeaderView = {
        let headerView = HTZProfileHeaderView()
        headerView.delegate = self
        return headerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess(noti:)), name: NSNotification.Name(kLoginSuccessNotification), object: nil)
    }
    
    
    override func configSubView() {
        super.configSubView()
        
        view.addSubview(tableView)
        headerView.frame = CGRect(x: 0, y: -44, width: kScreenWidth, height: 340)
        tableView.tableHeaderView = headerView
    }
    
    override func configData() {
        super.configData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        HTZMusicTool.showPlayBtn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.isHidden = false
        HTZMusicTool.hidePlayBtn()
    }
    
    @objc private func loginSuccess(noti: Notification) {
        self.headerView.iconImage =  HTZUserAccount.shared.headimgurl
        self.headerView.name =  HTZUserAccount.shared.name
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HTZProfileTableViewCellReuseID", for: indexPath) as! HTZProfileTableViewCell
        cell.imageName = dataArr[indexPath.row].imageName
        cell.title = dataArr[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let vc = HTZMyFavoriteViewController()
            vc.title = "我的收藏"
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 1 {
            let vc = HTZListenHistoryViewController()
            vc.title = "收听记录"
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 2 {
            let vc = HTZMyNotificationViewController()
            vc.title = "我的通知"
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
}

// MARK: - HTZProfileHeaderViewDelegate
extension HTZProfileViewController: HTZProfileHeaderViewDelegate {
    
    @objc func nameButtonClickAction() {
        let vc = HTZWechatLoginViewController()
        navigationController?.pushViewController(vc, animated: true)
        vc.loginResult = { loginModel in
            let dict:[String : Any?] = [
                "token":loginModel?.token,
                "name":loginModel?.name,
                "id":loginModel?.id,
                "union_id":loginModel?.union_id,
                "mobile":loginModel?.mobile,
                "gender":loginModel?.gender,
                "created_at":loginModel?.created_at,
                "avatar":loginModel?.avatar,
                "birthday_year":loginModel?.birthday_year,
                "country":loginModel?.wx_login_resp?.country,
                "unionid":loginModel?.wx_login_resp?.unionid,
//                "city":loginModel?.wx_login_resp?.city,
                "privilege":loginModel?.wx_login_resp?.privilege,
                "sex":loginModel?.wx_login_resp?.sex,
                "province":loginModel?.wx_login_resp?.province,
                "nickname":loginModel?.wx_login_resp?.nickname,
                "openid":loginModel?.wx_login_resp?.openid,
                "headimgurl":loginModel?.wx_login_resp?.headimgurl]
           
            
            HTZUserAccount.shared.saveUserAcountInfoWithDict(dict: dict as [String : Any])
            self.headerView.iconImage =  HTZUserAccount.shared.headimgurl
            self.headerView.name =  HTZUserAccount.shared.name
            // 发送网络状态改变的通知
            NotificationCenter.default.post(name: NSNotification.Name(kLoginSuccessNotification), object: nil)
        }
        print("点击登录")
    }
    
    
    @objc func functionTapAction(_ index: NSInteger) {
        if index == 1 {
            print("历史")
        } else if index == 2 {
            print("订阅")
        } else if index == 3 {
            print("收藏")
        }
        alert(message: "暂未开发")
    }
    
    @objc func iDownloadsClickAction() {
        print("我的下载")
        let vc = HTZMyDownloadedViewController()
        vc.title = "我的下载"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
