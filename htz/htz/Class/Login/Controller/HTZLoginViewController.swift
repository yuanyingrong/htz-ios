//
//  HTZLoginViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/28.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZLoginViewController: BaseViewController {

    private lazy var topImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        return imageView
    }()
    
    private lazy var userNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "邮箱/手机/用户名"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "密码"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        return textField
    }()
    
    private lazy var forgetPasswordButton: UIButton = {
        let forgetPasswordButton = UIButton(type: UIButton.ButtonType.custom)
        forgetPasswordButton.setTitle("忘记密码/注册", for: UIControl.State.normal)
        forgetPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        forgetPasswordButton.setTitleColor(UIColor.black, for: UIControl.State.normal)
        forgetPasswordButton.addTarget(self, action: #selector(forgetPasswordButtonClickAction), for: UIControl.Event.touchUpInside)
        return forgetPasswordButton
    }()
    
    private lazy var loginButton: UIButton = {
        let loginButton = UIButton(type: UIButton.ButtonType.custom)
        loginButton.setTitle("登录", for: UIControl.State.normal)
        loginButton.backgroundColor = UIColor.red
        loginButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        loginButton.cornerRadius = 22
        loginButton.addTarget(self, action: #selector(loginButtonClickAction), for: UIControl.Event.touchUpInside)
        return loginButton
    }()
    
    private lazy var leftLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.darkGray
        return line
    }()
    
    private lazy var middleLabel = UILabel(text: "快速登录", font: 13, textColor: UIColor.darkGray)
    
    private lazy var rightLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.darkGray
        return line
    }()
    
    private lazy var wechatButton: UIButton = {
        let wechatButton = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
        wechatButton.set(image: UIImage(named: "地图"), title: "微信登录", titlePosition: UIView.ContentMode.bottom, additionalSpacing: 8, state: UIControl.State.normal)
        wechatButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        wechatButton.addTarget(self, action: #selector(wechatButtonClickAction), for: UIControl.Event.touchUpInside)
        return wechatButton
    }()
    
    private lazy var qqButton: UIButton = {
        let qqButton = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        qqButton.set(image: UIImage(named: "地图"), title: "QQ登录", titlePosition: UIView.ContentMode.bottom, additionalSpacing: 8, state: UIControl.State.normal)
        qqButton.addTarget(self, action: #selector(qqButtonClickAction), for: UIControl.Event.touchUpInside)
        return qqButton
    }()
    
    private lazy var sinaButton: UIButton = {
        
        let sinaButton = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
//        sinaButton.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
//        sinaButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        sinaButton.set(image: UIImage(named: "地图"), title: "微博登录", titlePosition: UIView.ContentMode.bottom, additionalSpacing: 8, state: UIControl.State.normal)
        sinaButton.addTarget(self, action: #selector(sinaButtonClickAction), for: UIControl.Event.touchUpInside)
        return sinaButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    override func configSubView() {
        super.configSubView()
        
        view.backgroundColor = UIColor.colorWithHexString("F8F8FB")
        
        view.addSubview(topImageView)
        view.addSubview(userNameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(forgetPasswordButton)
        view.addSubview(loginButton)
        
        view.addSubview(leftLine)
        view.addSubview(middleLabel)
        view.addSubview(rightLine)
        
        view.addSubview(wechatButton)
        view.addSubview(qqButton)
        view.addSubview(sinaButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        topImageView.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.safeAreaLayoutGuide).offset(5.5 * kGlobelMargin)
            } else {
                make.top.equalTo(view).offset(5.5 * kGlobelMargin)
            }
            make.centerX.equalTo(view)
            make.size.equalTo(CGSize(width: 88, height: 88))
        }
        
        userNameTextField.snp.makeConstraints { (make) in
            make.top.equalTo(topImageView.snp.bottom).offset(8 * kGlobelMargin)
            make.left.right.equalTo(view).inset(kGlobelMargin * kGlobelMargin)
            make.height.equalTo(5 * kGlobelMargin)
        }
        
        passwordTextField.snp.makeConstraints { (make) in
            make.top.equalTo(userNameTextField.snp.bottom).offset(4 * kGlobelMargin)
            make.left.right.height.equalTo(userNameTextField)
        }
        
        forgetPasswordButton.snp.makeConstraints { (make) in
            make.top.equalTo(passwordTextField.snp.bottom).offset(0.5 * kGlobelMargin)
            make.right.equalTo(passwordTextField)
        }
        
        leftLine.snp.makeConstraints { (make) in
            make.centerY.equalTo(middleLabel)
            make.left.equalTo(loginButton)
            make.right.equalTo(middleLabel.snp.left).offset(-0.25 * kGlobelMargin)
            make.height.equalTo(1)
        }
        
        middleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(loginButton.snp.bottom).offset(11 * kGlobelMargin)
        }
        
        rightLine.snp.makeConstraints { (make) in
            make.centerY.equalTo(middleLabel)
            make.left.equalTo(middleLabel.snp.right).offset(0.25 * kGlobelMargin)
            make.right.equalTo(sinaButton)
            make.height.equalTo(1)
        }
        
        loginButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(passwordTextField.snp.bottom).offset(8 * kGlobelMargin)
            make.size.equalTo(CGSize(width: kScreenWidth * 0.6, height: CGFloat(5.5 * kGlobelMargin)))
        }
        
        wechatButton.snp.makeConstraints { (make) in
            make.top.size.equalTo(qqButton)
            make.right.equalTo(qqButton.snp.left).offset(-24)
        }
        
        qqButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(middleLabel.snp.bottom).offset(4 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 66, height: 66))
        }

        sinaButton.snp.makeConstraints { (make) in
            make.top.size.equalTo(qqButton)
            make.left.equalTo(qqButton.snp.right).offset(24)
        }
        
    }

}

// MARK: 按钮点击事件
extension HTZLoginViewController {
    
    // 登录
    @objc func loginButtonClickAction() {
        alertActionAlert(title: "提示", message: "点击了登录", confirmTitle: "我知道了")
        print("登录")
    }
    
    // 忘记密码/注册
    @objc func forgetPasswordButtonClickAction() {
        print("忘记密码/注册")
        let vc = HTZSignUpViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 微信
    @objc func wechatButtonClickAction() {
        print("微信")
        HTZAccountThirdLoginUtil.sharedInstance.getUserInfo(loginType: ThirdLoginType.weixin) { (loginResult, error) -> (Void) in
            print(loginResult)
        }
    }
    
    // QQ
    @objc func qqButtonClickAction() {
        print("QQ")
        HTZAccountThirdLoginUtil.sharedInstance.getUserInfo(loginType: ThirdLoginType.tencent) { (loginResult, error) -> (Void) in
            print(loginResult)
        }
    }
    
    // 新浪微博
    @objc func sinaButtonClickAction() {
        print("新浪微博")
        HTZAccountThirdLoginUtil.sharedInstance.getUserInfo(loginType: ThirdLoginType.weibo) { (loginResult, error) -> (Void) in
            print(loginResult)
        }
        
    }
    
}
