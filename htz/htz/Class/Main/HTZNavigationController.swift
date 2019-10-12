//
//  NavigationController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZNavigationController: UINavigationController,UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        var title: String?
        viewController.hidesBottomBarWhenPushed = children.count > 0
        if children.count > 0 {
            title = "返回"
//            if children.count == 1 {
//                title = children.first?.title
//            }
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(setHighlightedImg:"", title: title, target: self, action: #selector(popVC))
        }
        super.pushViewController(viewController, animated: animated)
    }
    
    @objc fileprivate func popVC() {
        popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return children.count != 1
    }
    
    // 是否支持屏幕翻转
    override var shouldAutorotate: Bool {
        get {
            return visibleViewController?.shouldAutorotate ?? false
        }
    }
    
    // 支持的屏幕旋转方向
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return visibleViewController?.supportedInterfaceOrientations ?? UIInterfaceOrientationMask.portrait
        }
    }
}
