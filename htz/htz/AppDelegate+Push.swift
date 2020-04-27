//
//  AppDelegate+Push.swift
//  htz
//
//  Created by 袁应荣 on 2020/3/30.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import Foundation

extension AppDelegate {
    
    func configPush(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        //推送代码
        let entity = JPUSHRegisterEntity()
        entity.types = 1 << 0 | 1 << 1 | 1 << 2
        JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
        //需要IDFA 功能，定向投放广告功能
        //let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        #if DEBUG
        let isProduction = false
        #else
        let isProduction = true
        #endif
        JPUSHService.setup(withOption: launchOptions, appKey: JAppKey, channel: "App Store", apsForProduction: isProduction, advertisingIdentifier: nil)
    }
    
    
}

extension AppDelegate : JPUSHRegisterDelegate {
    
     // 系统获取Token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
    // 获取token 失败
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
         print("did Fail To Register For Remote Notifications With Error: \(error)")
    }
    
    // 点推送进来执行这个方法
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
        
        UIWindow.yyr_currentViewController()?.alert(message: "didReceiveRemoteNotification\(userInfo)")
        
        // 程序后台
        if UIApplication.shared.applicationState == UIApplication.State.inactive {
//            guard let userInfo = userInfo else {
//                return
//            }
//            let apsInfo = userInfo["id"] as? String
            UIWindow.yyr_currentViewController()?.alertActionAlert(title: "程序后台 通知", message: "\(userInfo)", confirmTitle: "我知道了")
//            if apsInfo == "detail" {
//                let vc = HTZMyNotificationListViewController()
//                let nc = HTZNavigationController(rootViewController: vc)
//                self.window?.rootViewController?.present(nc, animated: true, completion: nil)
//            }
        }
        // 程序前台
        if application.applicationState == UIApplication.State.active {
//            guard let userInfo = userInfo else {
//                return
//            }
            UIWindow.yyr_currentViewController()?.alertActionAlert(title: "程序前台 通知", message: "\(userInfo)", confirmTitle: "我知道了")
        }
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!, withCompletionHandler completionHandler: ((Int) -> Void)!) {
        let userInfo = notification.request.content.userInfo
        if notification.request.trigger is UNPushNotificationTrigger {
             JPUSHService.handleRemoteNotification(userInfo)
            UIWindow.yyr_currentViewController()?.alert(message: "willPresent if\(userInfo)")
        } else {
            UIWindow.yyr_currentViewController()?.alert(message: "willPresent else\(userInfo)")
        }
        // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        let userInfo = response.notification.request.content.userInfo
        if response.notification.request.trigger is UNPushNotificationTrigger { // 点击推送消息进入APP
            JPUSHService.handleRemoteNotification(userInfo)
            let tabBarcontroller = window?.rootViewController as! HTZTabbarViewController
            tabBarcontroller.selectedIndex  = 3
            
            UIWindow.yyr_currentViewController()?.alert(message: "didReceive response if\(userInfo)")
        } else {
            UIWindow.yyr_currentViewController()?.alert(message: "didReceive response else\(userInfo)")
        }
        // 系统要求执行这个方法
        completionHandler()
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification!) {
        if let notification = notification { // 从通知界面直接进入应用
            UIWindow.yyr_currentViewController()?.alert(message: "从通知界面直接进入应用\(notification)")
        } else { // 从通知设置界面进入应用
            UIWindow.yyr_currentViewController()?.alert(message: "从通知设置界面进入应用")
        }
        printLog(notification)
    }
    
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable : Any]!) {
        printLog(info)
    }
    
    
}
