//
//  CurrentViewControllerUtil.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/30.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

class CurrentViewControllerUtil: NSObject {
    
    static let sharedInstance = CurrentViewControllerUtil()
    
    func getCurrentViewController() -> UIViewController? {
        
        if let window = UIApplication.shared.keyWindow {
            var keyWindow = UIApplication.shared.keyWindow
            
            // UIWindow.Level window三种等级 normal，alert，statusBar,可见normal才是我们真正要用到的，这段代码就是
            // 排除其他两种level，找到所需的normalWindow
            if window.windowLevel != UIWindow.Level.normal {
                let windows = UIApplication.shared.windows
                for tmp in windows {
                    if tmp.windowLevel == UIWindow.Level.normal {
                        keyWindow = tmp
                        break
                    }
                }
            }
            var vc = keyWindow?.rootViewController
            
            if (vc?.isKind(of: UITabBarController.self))! {
                vc = (vc as! UITabBarController).selectedViewController
            } else if (vc?.isKind(of: UINavigationController.self))! {
                vc = (vc as! UINavigationController).visibleViewController
            } else if vc?.presentedViewController != nil {
                vc = vc?.presentedViewController
            }
            return vc
        } else {
            return nil
        }
    }
    
}
