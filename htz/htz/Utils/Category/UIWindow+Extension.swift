//
//  UIWindow+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/30.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

extension UIWindow {
    
    static func yyr_currentViewController() -> UIViewController? {
        let window: UIWindow? = (UIApplication.shared.delegate?.window)!
        var topViewController = window?.rootViewController
        while true {
            if let viewController = topViewController?.presentingViewController {
                topViewController = viewController
            } else if let viewcontroller = topViewController,viewcontroller is UINavigationController, let viewController = (topViewController as! UINavigationController).topViewController {
                topViewController = viewController
            } else if let viewcontroller = topViewController, viewcontroller is UITabBarController {
                topViewController = (viewcontroller as! UITabBarController).selectedViewController
            } else {
                break
            }
        }
        return topViewController
    }
}
