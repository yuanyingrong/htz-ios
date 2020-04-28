//
//  HTZBindMobileViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/28.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZBindMobileViewController: HTZBaseViewController {
    
    var bindMoblieSuccessBlock: (()->())?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func configSubView() {
        super.configSubView()
        
        countDownTimerButton.clickedBlock = {[weak self] (button) -> Void in
            self?.view.endEditing(true)
            guard let mobile = self?.mobileTextField.text else {
                self?.countDownTimerButton.isCounting = false
                button.setTitle("获取验证码", for: .normal)
                self?.alertActionTipConfirmAlert(message: "请输入电话号码")
                return
            }
            if YYRUtilities.isTelNumber(num: mobile) {
                self?.countDownTimerButton.isCounting = true
                NetWorkRequest(API.getSmsCode(telephone: mobile)) { (response) -> (Void) in
                    printLog(response)
                    if response["code"] == "200" {
                        
                    }
                }
            } else {
                self?.countDownTimerButton.isCounting = false
                button.setTitle("获取验证码", for: .normal)
                self?.alertActionTipConfirmAlert(message: "您输入的电话号码有误，请重新输入！")
            }
        }
       
        view.addSubview(mobileTextField)
        view.addSubview(countDownTimerButton)
        view.addSubview(codeTextField)
        view.addSubview(confirmButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        mobileTextField.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.topMargin).offset(5 * kGlobelMargin)
            make.left.equalTo(view).offset(2 * kGlobelMargin)
            make.right.equalTo(countDownTimerButton.snp.left)
            make.height.equalTo(44)
        }
        
        countDownTimerButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(mobileTextField)
            make.right.equalTo(view).offset(-2 * kGlobelMargin)
            make.height.equalTo(44)
            make.width.equalTo(88)
        }
        
        codeTextField.snp.makeConstraints { (make) in
            make.left.equalTo(mobileTextField)
            make.top.equalTo(mobileTextField.snp.bottom).offset(2 * kGlobelMargin)
            make.right.equalTo(countDownTimerButton)
            make.height.equalTo(44)
        }
        
        confirmButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(codeTextField.snp.bottom).offset(5 * kGlobelMargin)
            make.width.equalTo(0.8 * kScreenWidth)
            make.height.equalTo(44)
        }
    }
    
    private lazy var mobileTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.placeholder = "请输入手机号"
        textField.borderStyle = .roundedRect
        return textField
    }()

    private lazy var countDownTimerButton: HTZCountDownTimerButton = {
        let button = HTZCountDownTimerButton()
        return button
    }()
    
    private lazy var codeTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .default
        textField.placeholder = "输入验证码"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("确定", for: UIControl.State.normal)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button.cornerRadius = 8
        button.addTarget(self, action: #selector(confirmButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
}


extension HTZBindMobileViewController {
    
    @objc func confirmButtonClickAction() {
        guard let mobile = mobileTextField.text else {
            self.alertActionTipConfirmAlert(message: "请输入电话号码")
            return
        }
        guard let code = codeTextField.text, code.length > 0 else {
            self.alertActionTipConfirmAlert(message: "请输入验证码")
            return
        }
        NetWorkRequest(API.bindTelephone(code: code, telephone: mobile)) {[weak self] (response) -> (Void) in
            printLog(response)
            if response["code"] == "200" {
                if let bindMoblieSuccessBlock = self?.bindMoblieSuccessBlock {
                    HTZUserAccount.shared.mobile = mobile
                    bindMoblieSuccessBlock()
                }
            }
        }
    }
}
