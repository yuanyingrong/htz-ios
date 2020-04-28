//
//  UIViewController+Alert.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/30.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func visibleViewControllerIfExist() -> UIViewController? {
        if (self.presentedViewController != nil) {
            return self.presentedViewController?.visibleViewControllerIfExist()
        }
        
        if self.isKind(of: UINavigationController.self) {
            return (self as! UINavigationController).topViewController?.visibleViewControllerIfExist()
        }
        
        if self.isKind(of: UITabBarController.self) {
            return (self as! UITabBarController).selectedViewController?.visibleViewControllerIfExist()
        }
        
        if self.isViewLoaded && ((self.view?.window) != nil) {
            return self
        } else {
            print(String(format: "visibleViewControllerIfExist:，找不到可见的viewController。self = %@, self.view.window = %@", self, self.view.window!))
            return nil
        }
    }
}

extension UIViewController {
    
    func alert(message:String) {
        let attr = NSMutableAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18),NSAttributedString.Key.foregroundColor : RGBHEXCOLOR(rgbValue: 0xFFFFFF)])
        // 初始化提示框
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.setValue(attr, forKey: "attributedMessage")
        let subView = alertController.view.subviews.first!.subviews.first
        let alertContentView = subView!.subviews.first
        alertContentView?.backgroundColor = UIColor.darkGray
        present(alertController, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertActionTipConfirmAlert(message:String) {
        self.alertActionAlert(title: "提示", message: message, confirmTitle: "我知道了")
    }
    
    func alertActionAlert(title: String, message:String, confirmTitle: String) {
        let attr = NSMutableAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),NSAttributedString.Key.foregroundColor : RGBHEXCOLOR(rgbValue: 0x334A60)])
        // 初始化提示框
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.setValue(attr, forKey: "attributedMessage")
        let confirmAction = UIAlertAction(title: confirmTitle, style: UIAlertAction.Style.default) { (action) in
            
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func alertConfirmCacellActionAlert(title: String, message:String, leftConfirmTitle: String, rightConfirmTitle: String, selectLeftBlock:(()->Void)?, selectRightBlock:(()->Void)?) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.alert)
        
        // 改变title的大小和颜色
        let titleAttr = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),NSAttributedString.Key.foregroundColor : RGBHEXCOLOR(rgbValue: 0x334A60)])
        alertController.setValue(titleAttr, forKey: "attributedTitle")
        
        // 改变message的大小和颜色
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        let messageAttr = NSMutableAttributedString(string: "\n\(message)", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor : RGBHEXCOLOR(rgbValue: 0x334A60), NSAttributedString.Key.paragraphStyle : paragraphStyle])
        alertController.setValue(messageAttr, forKey: "attributedMessage")
        
        let leftAction = UIAlertAction(title: leftConfirmTitle, style: UIAlertAction.Style.default) { (action) in
            if selectLeftBlock != nil {
                selectLeftBlock!()
            }
        }
        alertController.addAction(leftAction)
        
        let rightAction = UIAlertAction(title: rightConfirmTitle, style: UIAlertAction.Style.default) { (action) in
            if selectRightBlock != nil {
                selectRightBlock!()
            }
        }
        alertController.addAction(rightAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func alertWithActionSheetTitles(titles: [String], cancelStr: String?, selectBlock:@escaping ((NSInteger, String)->(Void))) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        alertController.view.tintColor = RGBHEXCOLOR(rgbValue: 0x334A60)
        
        for (index, value) in titles.enumerated() {
            let action = UIAlertAction(title: value, style: UIAlertAction.Style.default) { (action) in
                selectBlock(index, value)
            }
            alertController.addAction(action)
        }
        if cancelStr != nil {
            let action = UIAlertAction(title: cancelStr, style: UIAlertAction.Style.destructive, handler: nil)
            alertController.addAction(action)
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
