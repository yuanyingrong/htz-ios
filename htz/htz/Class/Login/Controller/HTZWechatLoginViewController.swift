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
//        view.addSubview(wechatImageView)
        view.addSubview(wechatButton)
        view.addSubview(bottomLabel)
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
            make.size.equalTo(CGSize(width: 160, height: 160))
        }
        
//        wechatImageView.snp.makeConstraints { (make) in
//            make.center.equalTo(view)
//            make.top.equalTo(topImageView.snp.bottom).offset(8 * kGlobelMargin)
//            make.size.equalTo(CGSize(width: 88, height: 88))
//        }


        wechatButton.snp.makeConstraints { (make) in
            make.center.equalTo(view)
            make.top.equalTo(topImageView.snp.bottom).offset(8 * kGlobelMargin)
            make.width.equalTo(kScreenWidth * 0.6)
            make.height.equalTo(66)
        }
        
        bottomLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-32)
        }
    }

    

    private lazy var topImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "htz_no_title"))
        return imageView
    }()
    
    private lazy var wechatImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "wechat"))
        return imageView
    }()

    
    private lazy var wechatButton: UIButton = {
        let wechatButton = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        wechatButton.setTitle("微信登陆", for: UIControl.State.normal)
        wechatButton.backgroundColor = .green
//        wechatButton.set(image: UIImage(named: "wechat"), title: "微信登录", titlePosition: UIView.ContentMode.bottom, additionalSpacing: 8, state: UIControl.State.normal)
//        wechatButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        wechatButton.addTarget(self, action: #selector(wechatButtonClickAction), for: UIControl.Event.touchUpInside)
        return wechatButton
    }()
    
    private lazy var bottomLabel: UILabel = {
        let label = UILabel(text: "登录即代表阅读并同意相关服务条款", font: 16, textColor: UIColor.green)
        return label
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
