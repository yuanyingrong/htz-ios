//
//  HTZProfileViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import Foundation

struct ProfileCell {
    
    var imageName: String?
    var title: String?
    
}

class HTZProfileViewController: HTZBaseViewController {

    override var pageTraceName: String? {
        return "Profile"
    }

    let dataArr: [ProfileCell] = {
        let dataArr = [ProfileCell(imageName: "favorite", title: "我的收藏"),ProfileCell(imageName: "history", title: "播放历史"), ProfileCell(imageName: "notification", title: "我的通知"), ProfileCell(imageName: "setting", title: "设置")]
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

        if let headimgurl = HTZUserAccount.shared.headimgurl, !headimgurl.isEmpty {
            self.headerView.iconImage = headimgurl
        } else {
            self.headerView.iconImage = nil
        }
        self.headerView.name =  HTZUserAccount.shared.name
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
        if let headimgurl = HTZUserAccount.shared.headimgurl, !headimgurl.isEmpty {
            self.headerView.iconImage = headimgurl
        } else {
            self.headerView.iconImage = nil
        }
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
            let vc = HTZMyNotificationListViewController()
            vc.title = "我的通知"
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 3 {
            let vc = HTZSettingViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
}

// MARK: - HTZProfileHeaderViewDelegate
extension HTZProfileViewController: HTZProfileHeaderViewDelegate {
    
    @objc func nameButtonClickAction() {
        HTZLog.info("PROFILE-VIEW", "用户点击头像/名称区域")
        if let token = HTZUserAccount.shared.token, !token.isEmpty {
            HTZLog.debug("PROFILE-VIEW", "用户已登录，token存在: \(token)")
            // 检查是否同时有unionid，确保用户信息完整
            if let unionid = HTZUserAccount.shared.unionid {
                HTZLog.debug("PROFILE-VIEW", "用户信息完整，unionid: \(unionid)")
                let vc = HTZPersonalProfileViewController()
                vc.changeSuccessBlock = {
                    if let headimgurl = HTZUserAccount.shared.headimgurl, !headimgurl.isEmpty {
                        self.headerView.iconImage = headimgurl
                    } else {
                        self.headerView.iconImage = nil
                    }
                    self.headerView.name =  HTZUserAccount.shared.name
                }
                navigationController?.pushViewController(vc, animated: true)
            } else {
                HTZLog.warning("PROFILE-VIEW", "用户token存在但unionid不存在，跳转到微信登录")
                // token存在但unionid不存在，可能需要重新登录
                HTZLoginManager.shared.jumpToWechatLogin(controller: self)
            }
        } else {
            HTZLog.info("PROFILE-VIEW", "用户未登录，跳转到微信登录")
            HTZLoginManager.shared.jumpToWechatLogin(controller: self)
        }
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
