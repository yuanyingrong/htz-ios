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
        let dataArr = [ProfileCell(imageName: "history", title: "我的收藏")]
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
        }
        
    }
    
}

// MARK: - HTZProfileHeaderViewDelegate
extension HTZProfileViewController: HTZProfileHeaderViewDelegate {
    
    @objc func nameButtonClickAction() {
        let vc = HTZLoginViewController()
        navigationController?.pushViewController(vc, animated: true)
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
