//
//  HTZHomeViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeViewController: HTZBaseViewController {
    
    // 图片
    private let pictures = ["banner_dian_zi_bao", "banner_zhu_zi_wan_nian_ding_lun", "http://wechatapppro-1252524126.file.myqcloud.com/appw8Gkxo2j3844/image/c0c2babbc244b2143a84d4eca6afe420.jpg","http://www.htz.org.cn/wp-content/themes/htz/images/banner_chuanxilu.jpg","http://new.htz.org.tw/wp-content/uploads/2019/02/初衷願景-背景-3.jpg","http://new.htz.org.tw/wp-content/uploads/2019/02/IMG_1378.jpg"]

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        
        view.addSubview(searchVew)
        view.addSubview(cycleView)
        view.addSubview(bottomView)
        
        searchVew.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(kStatusBarHeight)
            make.left.right.equalTo(view)
            
        }
        // 滚动视图
        cycleView.pictures = pictures
        cycleView.snp.makeConstraints { (make) in
            make.top.equalTo(searchVew.snp.bottom).offset(2 * kGlobelMargin)
            make.height.equalTo(180)
            make.left.right.equalTo(view)
        }
        
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(cycleView.snp.bottom)
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
        
        homeViewModel.requestData(isPullDown: true) { (success) in
            self.bottomView.dataArr = self.homeViewModel.dataArr
        }
    }

    private lazy var homeViewModel: HTZHomeViewModel = HTZHomeViewModel()
    
    private lazy var searchVew: HTZHomeSearchView = {
        let searchVew = HTZHomeSearchView()
        searchVew.delegate = self
        return searchVew
    }()
    
    // 默认滚动视图
    private lazy var cycleView: HTZCycleView = {
        let cycleView = HTZCycleView(frame: CGRect.zero)
        cycleView.delegate = self
        return cycleView
    }()

    private lazy var bottomView: HTZHomeTitleCollectionView = {
        let view = HTZHomeTitleCollectionView()
        view.title = "推荐专辑"
        view.delegate = self
        return view
    }()
}

// MARK: - HTZCycleViewDelegate
extension HTZHomeViewController: HTZCycleViewDelegate {
    
    internal func htzCycleView(cycleView: HTZCycleView, didSelectItemAt index: Int) {
        print(index)
//        let vc = HTZVideoPlayViewController(urlStr: "http://htzshanghai.top/resources/videos/others/never_give_up.mp4")
        
        if index != 2 {
            let vc = HTZVideoPlayViewController()
            let str = index == 0 ? "never_give_up.mp4" : (index == 1 ? "steven_jobs.flv" : "SteveVai_Tender_Surrender.mp4")
            vc.videoUrl = "http://htzshanghai.top/resources/videos/others/"+str
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = HTZVideoPlayTableViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - HTZHomeTitleCollectionViewDelegate
extension HTZHomeViewController: HTZHomeTitleCollectionViewDelegate {
    @objc internal func moreButtonClickAtion() {
        print("更多")
    }
    
    @objc internal func collectionViewdidSelectItemAt(_ indexPath: IndexPath) {
        if indexPath.row > 2 {
             alert(message: "暂未上架")
            return
        }
        let vc = HTZAlbumListViewController()
        vc.title = homeViewModel.dataArr[indexPath.row]?.name
        homeViewModel.dataArr[indexPath.row]!.index = indexPath.row
        vc.sutraInfoModel = homeViewModel.dataArr[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
        print(indexPath.row)
    }
    
}

// MARK: - HTZHomeSearchViewDelegate
extension HTZHomeViewController: HTZHomeSearchViewDelegate {
    
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
