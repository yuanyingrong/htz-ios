//
//  HTZSignUpViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/30.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZSignUpViewController: HTZBaseViewController {
    
    private lazy var topImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        return imageView
    }()
    
    private lazy var mobileTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入手机号码"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        return textField
    }()
    
    private lazy var codeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "短信验证码"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        return textField
    }()
    
    private lazy var sendCodeButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("发送验证码", for: UIControl.State.normal)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button.cornerRadius = 8
        button.addTarget(self, action: #selector(sendCodeButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var userNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "用户名"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "密码"
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        return textField
    }()
    
    private lazy var protocolButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("已同意《黄庭书院用户协议和隐私条款》", for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(UIColor.red, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(protocolButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var signUpButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("注册", for: UIControl.State.normal)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button.cornerRadius = 22
        button.addTarget(self, action: #selector(signUpButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    override func configSubView() {
        super.configSubView()
        
        view.backgroundColor = UIColor.colorWithHexString("F8F8FB")
        
        view.addSubview(topImageView)
        view.addSubview(mobileTextField)
        view.addSubview(codeTextField)
        view.addSubview(sendCodeButton)
        view.addSubview(userNameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(protocolButton)
        view.addSubview(signUpButton)

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
        
        mobileTextField.snp.makeConstraints { (make) in
            make.top.equalTo(topImageView.snp.bottom).offset(8 * kGlobelMargin)
            make.left.right.equalTo(view).inset(kGlobelMargin * kGlobelMargin)
            make.height.equalTo(5 * kGlobelMargin)
        }
        
        codeTextField.snp.makeConstraints { (make) in
            make.top.equalTo(mobileTextField.snp.bottom).offset(4 * kGlobelMargin)
            make.left.height.equalTo(mobileTextField)
        }

        sendCodeButton.snp.makeConstraints { (make) in
            make.left.equalTo(codeTextField.snp.right).offset(kGlobelMargin)
            make.centerY.equalTo(codeTextField)
            make.right.equalTo(mobileTextField)
            make.width.equalTo(16 * kGlobelMargin)
        }

        userNameTextField.snp.makeConstraints { (make) in
            make.top.equalTo(codeTextField.snp.bottom).offset(4 * kGlobelMargin)
            make.left.right.height.equalTo(mobileTextField)
        }

        passwordTextField.snp.makeConstraints { (make) in
            make.top.equalTo(userNameTextField.snp.bottom).offset(4 * kGlobelMargin)
            make.left.right.height.equalTo(userNameTextField)
        }

        protocolButton.snp.makeConstraints { (make) in
            make.top.equalTo(passwordTextField.snp.bottom).offset(0.5 * kGlobelMargin)
            make.centerX.equalTo(view)
        }

        signUpButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(protocolButton.snp.bottom).offset(8 * kGlobelMargin)
            make.size.equalTo(CGSize(width: kScreenWidth * 0.6, height: CGFloat(5.5 * kGlobelMargin)))
        }
        
    }
    
}

// MARK: 按钮点击事件
extension HTZSignUpViewController {
    
    // 发送短信验证码
    @objc private func sendCodeButtonClickAction() {
        alertActionAlert(title: "提示", message: "点击了发送短信验证码", confirmTitle: "我知道了")
        print("发送短信验证码")
    }
    
    // 用户协议
    @objc private func protocolButtonClickAction() {
        alertActionAlert(title: "提示", message: "点击了用户协议", confirmTitle: "我知道了")
        print("用户协议")
    }
    
    // 注册
    @objc private func signUpButtonClickAction() {
        alertActionAlert(title: "提示", message: "点击了注册", confirmTitle: "我知道了")
        print("注册")
    }
}
