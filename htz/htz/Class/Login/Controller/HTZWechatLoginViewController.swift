//
//  HTZWechatLoginViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/3/10.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZWechatLoginViewController: HTZBaseViewController {
    
    var loginResult: ((HTZLoginModel?) -> (Void))?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func configSubView() {
        super.configSubView()
        
        view.backgroundColor = UIColor.colorWithHexString("F8F8FB")
        
        view.addSubview(topImageView)
        
        view.addSubview(wechatButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        topImageView.snp.makeConstraints { (make) in
//            if #available(iOS 11.0, *) {
//                make.top.equalTo(view.safeAreaLayoutGuide).offset(5.5 * kGlobelMargin)
//            } else {
//                make.top.equalTo(view).offset(5.5 * kGlobelMargin)
//            }
            make.centerX.equalTo(view)
            make.size.equalTo(CGSize(width: 120, height: 120))
        }
        
        
        wechatButton.snp.makeConstraints { (make) in
            make.center.equalTo(view)
            make.top.equalTo(topImageView.snp.bottom).offset(8 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 66, height: 66))
        }
        
        
    }

    

    private lazy var topImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        return imageView
    }()
    
    private lazy var wechatButton: UIButton = {
        let wechatButton = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        wechatButton.set(image: UIImage(named: "地图"), title: "微信登录", titlePosition: UIView.ContentMode.bottom, additionalSpacing: 8, state: UIControl.State.normal)
        wechatButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        wechatButton.addTarget(self, action: #selector(wechatButtonClickAction), for: UIControl.Event.touchUpInside)
        return wechatButton
    }()

}

// MARK: 按钮点击事件
extension HTZWechatLoginViewController {
    
    
    // 微信
    @objc func wechatButtonClickAction() {
        print("微信")
        HTZAccountThirdLoginUtil.sharedInstance.getUserInfo(loginType: ThirdLoginType.weixin) { (loginResult, error) -> (Void) in
//            print(loginResult)
            if let result = self.loginResult {
                result(loginResult)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
}
