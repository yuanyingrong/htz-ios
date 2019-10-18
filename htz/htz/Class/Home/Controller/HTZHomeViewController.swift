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
    private let pictures = ["banner_dian_zi_bao", "banner_zhu_zi_wan_nian_ding_lun", "https://goodreading.mobi/studentapi/userfiles/banner/student/home/studenttj.png"]
//    ["https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_tz.png", "https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_dzsyy.png", "https://goodreading.mobi/studentapi/userfiles/banner/student/home/studenttj.png"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        
        view.addSubview(searchVew)
        view.addSubview(cycleView)
        view.addSubview(bottomView)
        
        searchVew.snp.makeConstraints { (make) in
            make.top.equalTo(view).offset(44)
            make.left.right.equalTo(view)
            
        }
        // 滚动视图
        cycleView.pictures = pictures
        cycleView.snp.makeConstraints { (make) in
            make.top.equalTo(searchVew.snp.bottom).offset(16)
            make.height.equalTo(180)
            make.left.right.equalTo(view)
        }
        
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(cycleView.snp.bottom)
            make.left.right.bottom.equalTo(view)
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
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
        vc.title = homeViewModel.dataArr[indexPath.row]?.title
        homeViewModel.dataArr[indexPath.row]!.index = indexPath.row
        vc.albumModel = homeViewModel.dataArr[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
        print(indexPath.row)
    }
    
}

// MARK: - HTZHomeSearchViewDelegate
extension HTZHomeViewController: HTZHomeSearchViewDelegate {
    
    @objc func searchClickAction() {
        let vc = HTZSearchViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }

    @objc internal func recordButtonClickAction() {
        print("333")
    }
}
