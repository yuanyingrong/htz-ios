//
//  HTZHomeViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeViewController: BaseViewController {
    
    private lazy var homeViewModel: HTZHomeViewModel = HTZHomeViewModel()
    
    private lazy var searchVew: HTZHomeSearchView = HTZHomeSearchView()
    
    
    // 图片
    private let pictures = ["https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_tz.png", "https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_dzsyy.png", "https://goodreading.mobi/studentapi/userfiles/banner/student/home/studenttj.png"]
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.gray
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
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }

    override func configData() {
        super.configData()
        
        homeViewModel.requestData(isPullDown: true) { (success) in
            self.bottomView.dataArr = self.homeViewModel.dataArr
        }
    }

}

// MARK: - HTZCycleViewDelegate
extension HTZHomeViewController: HTZCycleViewDelegate {
    
    internal func htzCycleView(cycleView: HTZCycleView, didSelectItemAt index: Int) {
        print(index)
    }
}

// MARK: - HTZHomeTitleCollectionViewDelegate
extension HTZHomeViewController: HTZHomeTitleCollectionViewDelegate {
    @objc internal func moreButtonClickAtion() {
        print("更多")
    }
    
    @objc internal func collectionViewdidSelectItemAt(_ indexPath: IndexPath) {
        if indexPath.row > 0 {
             alert(message: "暂无数据")
            return
        }
        let vc = HTZAlbumListViewController()
        vc.title = homeViewModel.dataArr[indexPath.row]?.title
        vc.albumModel = homeViewModel.dataArr[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
        print(indexPath.row)
    }
    
}
