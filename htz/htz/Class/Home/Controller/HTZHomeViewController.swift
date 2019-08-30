//
//  HTZHomeViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeViewController: BaseViewController {
    
    lazy var homeViewModel: HTZHomeViewModel = HTZHomeViewModel()
    
    lazy var searchVew: HTZSearchView = HTZSearchView()
    
    
    // 图片
    let pictures = ["https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_tz.png", "https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_dzsyy.png", "https://goodreading.mobi/studentapi/userfiles/banner/student/home/studenttj.png"]
    
    // 默认滚动视图
    lazy var cycleView: HTZCycleView = {
        let cycleView = HTZCycleView(frame: CGRect.zero)
        cycleView.delegate = self
        return cycleView
    }()

    lazy var bottomView: HTZHomeTitleCollectionView = {
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
//            make.height.equalTo(66)
        }
        // 滚动视图
        cycleView.pictures = pictures
        cycleView.snp.makeConstraints { (make) in
            make.top.equalTo(searchVew.snp_bottom).offset(16)
            make.height.equalTo(180)
            make.left.right.equalTo(view)
        }
        
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(cycleView.snp_bottom)
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
        bottomView.dataArr = homeViewModel.dataArr
//        bottomView.
    }

}

// MARK: - HTZCycleViewDelegate
extension HTZHomeViewController: HTZCycleViewDelegate {
    
    func htzCycleView(cycleView: HTZCycleView, didSelectItemAt index: Int) {
        print(index)
    }
}

// MARK: - HTZHomeTitleCollectionViewDelegate
extension HTZHomeViewController: HTZHomeTitleCollectionViewDelegate {
    @objc func moreButtonClickAtion() {
        print("更多")
    }
    
    @objc func collectionViewdidSelectItemAt(_ indexPath: IndexPath) {
        let vc = BaseViewController()
        vc.title = homeViewModel.dataArr[indexPath.row].title
        navigationController?.pushViewController(vc, animated: true)
        print(indexPath.row)
    }
    
}
