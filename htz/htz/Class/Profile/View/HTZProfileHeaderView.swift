//
//  HTZProfileHeaderView.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/26.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZProfileHeaderViewDelegate: NSObjectProtocol {
    
    func nameButtonClickAction()
    
    /// index: 1历史 2订阅 3收藏
    func functionTapAction(_ index:NSInteger)
    
    func iDownloadsClickAction()
}
class HTZProfileHeaderView: BaseView {
    
    weak var delegate:HTZProfileHeaderViewDelegate?
    
    private lazy var bgImageView: UIImageView = {
        let bgImageView = UIImageView(image: UIImage(named: "my_bk"))
        bgImageView.isUserInteractionEnabled = true
        return bgImageView
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.cornerRadius = 44
        iconImageView.image = UIImage(named: "favorite")
        return iconImageView
    }()
    
    private lazy var nameButton: UIButton = {
        let nameButton = UIButton(type: UIButton.ButtonType.custom)
        nameButton.setTitle("点击登录", for: UIControl.State.normal)
        nameButton.addTarget(self, action: #selector(nameBtnClickAction), for: UIControl.Event.touchUpInside)
        return nameButton
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView(image: UIImage(named: "enter"))
        return arrowImageView
    }()
    
    private lazy var functionView: HTZProfileFunctionView = {
        let functionView = HTZProfileFunctionView()
        functionView.delegate = self
        return functionView
    }()
    
    private lazy var iDownloadsButton: UIButton = {
        let iDownloadsButton = UIButton(type: UIButton.ButtonType.custom)
        iDownloadsButton.setTitle("我的下载", for: UIControl.State.normal)
        iDownloadsButton.backgroundColor = UIColor.red
        iDownloadsButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        iDownloadsButton.cornerRadius = 22
        iDownloadsButton.addTarget(self, action: #selector(iDownloadsButtonClickAction), for: UIControl.Event.touchUpInside)
        return iDownloadsButton
    }()
    
    override func configSubviews() {
        super.configSubviews()
        
        addSubview(bgImageView)
        bgImageView.addSubview(iconImageView)
        bgImageView.addSubview(nameButton)
        bgImageView.addSubview(arrowImageView)
        
        addSubview(functionView)
        addSubview(iDownloadsButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        bgImageView.snp_makeConstraints { (make) in
            make.left.top.right.equalTo(self)
            make.height.equalTo(200)
        }
        
        iconImageView.snp_makeConstraints { (make) in
            make.left.equalTo(bgImageView).offset(16)
            make.size.equalTo(CGSize(width: 44, height: 44))
            make.bottom.equalTo(bgImageView).offset(-16)
        }
        
        nameButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.left.equalTo(iconImageView.snp_right).offset(32)
        }
        
        arrowImageView.snp_makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.right.equalTo(bgImageView).offset(-32)
        }
        
        functionView.snp_makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(bgImageView.snp_bottom)
            make.height.equalTo(66)
        }
        
        iDownloadsButton.snp_makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.size.equalTo(CGSize(width: 0.8 * kScreenWidth, height: 44))
            make.bottom.equalTo(self).offset(-16)
        }
    }

}

// MARK: 点击事件
extension HTZProfileHeaderView {
    
    @objc private func nameBtnClickAction() {
        if delegate != nil && (delegate?.responds(to: Selector.init(("nameButtonClickAction"))))! {
            delegate?.nameButtonClickAction()
        }
    }
    
    @objc private func iDownloadsButtonClickAction() {
        if delegate != nil && (delegate?.responds(to: Selector(("iDownloadsClickAction"))))! {
            delegate?.iDownloadsClickAction()
        }
    }
}

// MARK: HTZProfileFunctionViewDelegate
extension HTZProfileHeaderView: HTZProfileFunctionViewDelegate {
    @objc internal func functionTapAction(_ index: NSInteger) {
        if delegate != nil && (delegate?.responds(to: Selector(("functionTapAction:"))))! {
            delegate?.functionTapAction(index)
        }
    }
    
    
}
