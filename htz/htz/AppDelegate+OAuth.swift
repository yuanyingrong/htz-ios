//
//  AppDelegate+OAuth.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/29.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation


extension AppDelegate {
    
    // iOS9以上
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let urlKey: String = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String
        if urlKey == "com.sina.weibo" { // 新浪微博 的回调
            return WeiboSDK.handleOpen(url, delegate: HTZAccountThirdLoginUtil.sharedInstance)
        }
        if urlKey == "com.tencent.xin" { // 微信 的回调
            return WXApi.handleOpen(url, delegate: HTZAccountThirdLoginUtil.sharedInstance)
        }
        if  urlKey == "com.tencent.mqq" {
            TencentOAuth.handleOpen(url)
        }
        return true
    }
    
    // iOS9以下
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if sourceApplication == "com.sina.weibo" { // 新浪微博 的回调
            return WeiboSDK.handleOpen(url, delegate: HTZAccountThirdLoginUtil.sharedInstance)
        }
        if sourceApplication == "com.tencent.xin" { // 微信 的回调
            return WXApi.handleOpen(url, delegate: HTZAccountThirdLoginUtil.sharedInstance)
        }
        if  sourceApplication == "com.tencent.mqq" {
            TencentOAuth.handleOpen(url)
        }
        return true
    }
}


