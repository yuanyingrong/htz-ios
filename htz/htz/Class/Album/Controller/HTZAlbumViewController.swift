//
//  HTZAlbumViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZAlbumViewController: HTZBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        
        view.addSubview(searchVew)
        view.addSubview(bottomView)
        view.addSubview(loginButton)
        
        searchVew.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(kStatusBarHeight)
            make.left.right.equalTo(view) 
        }
        
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(searchVew.snp.bottom)
            make.left.right.bottom.equalTo(view)
        }
        
        loginButton.snp.makeConstraints { (make) in
            make.center.equalTo(view)
//            make.top.equalTo(searchVew.snp.bottom).offset(8 * kGlobelMargin)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess(noti:)), name: NSNotification.Name(kLoginSuccessNotification), object: nil)
    }
    
    @objc private func loginSuccess(noti: Notification) {
        configData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        configData()
        HTZMusicTool.showPlayBtn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        HTZMusicTool.hidePlayBtn()
    }
    
    override func configData() {
        super.configData()
        
        albumViewModel.requestData(page_index: 0) { (success, code) in
            self.bottomView.dataArr = self.albumViewModel.dataArr
            
            self.loginButton.isHidden = code == "200"
            
        }
    }
    
    private lazy var albumViewModel: HTZAlbumViewModel = HTZAlbumViewModel()
    
    @objc private func loginButtonClickAction() { // 跳转登陆
        HTZLoginManager.shared.jumpToWechatLogin(controller: self)
    }
    
    private lazy var searchVew: HTZHomeSearchView = {
        let searchVew = HTZHomeSearchView()
        searchVew.delegate = self
        return searchVew
    }()
        
    private lazy var bottomView: HTZHomeTitleCollectionView = {
        let view = HTZHomeTitleCollectionView()
        view.title = "所有专辑"
        view.delegate = self
        return view
    }()
    
    private lazy var loginButton: UIButton = {
        let loginButton = UIButton(type: .custom)
        loginButton.setTitle("登录后查看更多精彩内容", for: .normal)
        loginButton.setTitleColor(.darkText, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonClickAction), for: .touchUpInside)
        loginButton.isHidden = true
        return loginButton
    }()
}

    // MARK: - HTZHomeTitleCollectionViewDelegate
extension HTZAlbumViewController: HTZHomeTitleCollectionViewDelegate {
    @objc internal func moreButtonClickAtion() {
        print("更多")
    }
    
    @objc internal func collectionViewdidSelectItemAt(_ indexPath: IndexPath) {
       
        let vc = HTZAlbumListViewController()
        vc.title = albumViewModel.dataArr[indexPath.row]?.name
        albumViewModel.dataArr[indexPath.row]!.index = indexPath.row
        albumViewModel.dataArr[indexPath.row]!.isAlbum = true
        vc.sutraInfoModel = albumViewModel.dataArr[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
        print(indexPath.row)
    }
    
}

    // MARK: - HTZHomeSearchViewDelegate
extension HTZAlbumViewController: HTZHomeSearchViewDelegate {
    
    @objc func searchClickAction() {
        let vc = HTZSearchViewController()
        //        vc.modalPresentationStyle = .fullScreen
        //        self.present(vc, animated: true, completion: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc internal func recordButtonClickAction() {
        print("333")
        if let _ = HTZUserAccount.shared.token { // 已登录，跳转历史记录
            
        } else { // 跳转登陆
            HTZLoginManager.shared.jumpToWechatLogin(controller: self)
        }
    }
}
