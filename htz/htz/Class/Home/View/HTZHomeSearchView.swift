//
//  HTZHomeSearchView.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeSearchView: BaseView {
    
    private lazy var contentView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.white
        view.cornerRadius = 22
        view.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        view.layer.borderWidth = 2
        return view
    }()
    
    private lazy var leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "home_icon_select")
        return imageView
    }()
    
    private lazy var middleView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.white
        view.cornerRadius = 15
        view.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        view.layer.borderWidth = 2
        return view
    }()
    
    private lazy var searchImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "search")
        return imageView
    }()
    
    private lazy var rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "time")
        return imageView
    }()
    
    override func configSubviews() {
        super.configSubviews()
        addSubview(contentView)
        contentView.addSubview(leftImageView)
        contentView.addSubview(middleView)
        middleView.addSubview(searchImageView)
        contentView.addSubview(rightImageView)
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(middleViewTapGestrueAction))
        middleView.addGestureRecognizer(tapGesture)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        contentView.snp.makeConstraints { (make) in
            //            make.top.bottom.equalTo(self)
            make.left.top.equalTo(self).offset(kGlobelMargin)
            make.right.bottom.equalTo(self).offset(-kGlobelMargin)
        }
        
        leftImageView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(contentView)
            make.left.equalTo(contentView).offset(2 * kGlobelMargin)
        }
        
        middleView.snp.makeConstraints { (make) in
            make.left.equalTo(leftImageView.snp_rightMargin).offset(2 * kGlobelMargin)
            make.top.equalTo(contentView).offset(kGlobelMargin)
            make.bottom.equalTo(contentView).offset(-kGlobelMargin)
            make.height.equalTo(30)
        }
        
        searchImageView.snp.makeConstraints { (make) in
            make.left.equalTo(middleView).offset(2 * kGlobelMargin)
            make.centerY.equalTo(middleView)
        }
        
        rightImageView.snp.makeConstraints { (make) in
            make.left.equalTo(middleView.snp_right).offset(2 * kGlobelMargin)
            make.right.equalTo(contentView).offset(-kGlobelMargin)
            make.centerY.equalTo(contentView)
        }
    }
    
}

// MARK: - 手势点击
extension HTZHomeSearchView {
    
    @objc private func middleViewTapGestrueAction() {
        
        
    }
}
