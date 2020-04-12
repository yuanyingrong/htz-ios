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
        
        searchVew.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(64)
            make.left.right.equalTo(view)
            
        }
        
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(searchVew.snp.bottom)
            make.left.right.bottom.equalTo(view)
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
        
        albumViewModel.requestData(isPullDown: true) { (success) in
            self.bottomView.dataArr = self.albumViewModel.dataArr
        }
    }
    
    private lazy var albumViewModel: HTZAlbumViewModel = HTZAlbumViewModel()
    
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
}

    // MARK: - HTZHomeTitleCollectionViewDelegate
extension HTZAlbumViewController: HTZHomeTitleCollectionViewDelegate {
    @objc internal func moreButtonClickAtion() {
        print("更多")
    }
    
    @objc internal func collectionViewdidSelectItemAt(_ indexPath: IndexPath) {
        if indexPath.row > 2 {
            alert(message: "暂未上架")
            return
        }
        let vc = HTZAlbumListViewController()
        vc.title = albumViewModel.dataArr[indexPath.row]?.name
        albumViewModel.dataArr[indexPath.row]!.index = indexPath.row
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
                
                // 发送网络状态改变的通知
                NotificationCenter.default.post(name: NSNotification.Name(kLoginSuccessNotification), object: nil)
            }
        }
    }
}
