//
//  HTZSearchView.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/6.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZSearchView: UIView {
    
    
    private lazy var contentView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.white
        view.cornerRadius = 22
//        view.ma
        
        return view
    }()
    private lazy var leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "home_icon_select")
        return imageView
    }()
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.cornerRadius = 22
        searchBar.layer.borderWidth = 2
        searchBar.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        searchBar.placeholder = "搜索"
        for view in searchBar.subviews.last!.subviews {
            if(type(of: view) == NSClassFromString("UISearchBarBackground")) {
                view.alpha = 0.0
            } else if(type(of: view) == NSClassFromString("UISearchBarTextField")) {
                print("Keep textfiedld bkg color")
            } else {
                view.alpha = 0.0
            }
        }
        return searchBar
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - 设置UI
extension HTZSearchView {
    
    func initUI() {
        self.addSubview(contentView)
        contentView.addSubview(leftImageView)
        contentView.addSubview(searchBar)
        
        contentView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self).offset(4)
            make.right.equalTo(self).offset(-4)
        }
        
        leftImageView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(contentView)
            make.left.equalTo(contentView).offset(16)
        }
        
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(4)
            make.left.equalTo(leftImageView.snp.rightMargin).offset(16)
            make.right.equalTo(contentView).offset(-8)
            make.height.equalTo(44)
            make.bottom.equalTo(contentView).offset(-4)
        }
    }
}


extension HTZSearchView: UISearchBarDelegate {
    
    
}
