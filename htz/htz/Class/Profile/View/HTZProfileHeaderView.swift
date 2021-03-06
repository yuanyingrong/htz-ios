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
    
    var iconImage: String? {
        didSet {
            if let iconImage = iconImage, iconImage.length > 0 {
                iconImageView.wb_setImageWith(urlStr: iconImage, placeHolder: "头像")
            }
        }
    }
    
    var name: String? {
        didSet {
            if let name = name {
                nameButton.setTitle(name, for: UIControl.State.normal)
            }
        }
    }
    
    weak var delegate: HTZProfileHeaderViewDelegate?
    
    private lazy var bgImageView: UIImageView = {
        let bgImageView = UIImageView(image: UIImage(named: "my_bk"))
        bgImageView.isUserInteractionEnabled = true
        return bgImageView
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.cornerRadius = 44
        if let headimgurl = HTZUserAccount.shared.headimgurl {
            iconImageView.wb_setImageWith(urlStr: headimgurl, placeHolder: "头像")
        } else {
           iconImageView.image = UIImage(named: "头像")
        }
        
        return iconImageView
    }()
    
    private lazy var nameButton: UIButton = {
        let nameButton = UIButton(type: UIButton.ButtonType.custom)
        if let name = HTZUserAccount.shared.name {
            nameButton.setTitle(name, for: UIControl.State.normal)
        } else {
           nameButton.setTitle("", for: UIControl.State.normal)
        }
        
        nameButton.addTarget(self, action: #selector(nameBtnClickAction), for: UIControl.Event.touchUpInside)
        return nameButton
    }()

    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView(image: UIImage(named: "enter"))
        return arrowImageView
    }()
    
    private lazy var tapView: UIView = {
        let view = UIView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nameBtnClickAction)))
        return view
    }()
    
    private lazy var functionView: HTZProfileFunctionView = {
        let functionView = HTZProfileFunctionView()
        functionView.delegate = self
        functionView.isHidden = true // 暂时隐藏
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
        bgImageView.addSubview(tapView)
        
        addSubview(functionView)
        addSubview(iDownloadsButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        bgImageView.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(self)
            make.height.equalTo(200)
        }
        
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(bgImageView).offset(16)
            make.size.equalTo(CGSize(width: 44, height: 44))
            make.bottom.equalTo(bgImageView).offset(-16)
        }
        
        nameButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.left.equalTo(iconImageView.snp.right).offset(32)
        }
        
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.right.equalTo(bgImageView).offset(-32)
        }
        
        tapView.snp.makeConstraints { (make) in
            make.left.equalTo((nameButton))
            make.top.equalTo(nameButton).offset(-kGlobelMargin)
            make.right.equalTo(arrowImageView)
            make.bottom.equalTo(nameButton).offset(kGlobelMargin)
        }
        
        functionView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(bgImageView.snp.bottom)
            make.height.equalTo(1) // 66
        }
        
        iDownloadsButton.snp.makeConstraints { (make) in
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
        if delegate != nil && (delegate?.responds(to: #selector(self.functionTapAction(_:))))! {
            delegate?.functionTapAction(index)
        }
    }
    
    
}
