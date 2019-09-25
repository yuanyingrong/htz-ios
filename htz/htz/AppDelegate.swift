//
//  AppDelegate.swift
//  htz
//
//  Created by 袁应荣 on 2019/5/27.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var palyButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setBackgroundImage(UIImage(named: "play_normal"), for: UIControl.State.normal)
//        button.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(topbarPlayButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 初始化主窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        window?.rootViewController = HTZTabbarViewController()
        window?.makeKeyAndVisible()
        
        // 初始化全局播放按钮
        initPlayButton()
        
        // 初始化播放器
        HTZPlayViewController.sharedInstance.initialData()
        
        // 网络监测
        networkStateCheck()
        
        // 告诉app支持后台播放
         let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.init())
        } catch  {
            print(error)
        }
       
        
        
        
        
//        #if DEBUG
//        pgyerCrash()
//        #endif
        
        return true
    }
    
    ///
    func initPlayButton() {
        self.window?.addSubview(palyButton)
        
        palyButton.snp.makeConstraints({ (make) in
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.window!.safeAreaLayoutGuide)
            } else {
                make.bottom.equalTo(self.window!)
            }
            make.centerX.equalTo(self.window!)
            make.width.height.equalTo(44)
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(playStatusChanged(noti:)), name: NSNotification.Name(kPlayStateChangeNotification), object: nil)
    }
    
    @objc private func topbarPlayButtonClickAction() {
        if HTZMusicTool.musicList() != nil {
            let nav = UINavigationController(rootViewController: HTZPlayViewController.sharedInstance)
            HTZPlayViewController.sharedInstance.playMusic()
            nav.modalPresentationStyle = .fullScreen
            HTZMusicTool.visibleViewController()?.present(nav, animated: true, completion: nil)
        } else {
            HTZMusicTool.visibleViewController()?.alert(message: "暂无播放内容")
        }
       
    }
    
    @objc private func playStatusChanged(noti: Notification) {
        DispatchQueue.main.async {
            if let isPlaying = HTZPlayViewController.sharedInstance.isPlaying, isPlaying {
                self.palyButton.setBackgroundImage(UIImage(named: "play_normal"), for: UIControl.State.normal)
                self.palyButton.setImage(UIImage(named: ""), for: UIControl.State.normal)
            } else {
                self.palyButton.setBackgroundImage(UIImage(named: "play_normal"), for: UIControl.State.normal)
                self.palyButton.setImage(UIImage(named: "tabbar_play"), for: UIControl.State.normal)
            }
        }
    }
 
    /// 网络监测
    func networkStateCheck() {
        let manager = NetworkReachabilityManager()
        manager?.listener = { status in
            switch status {
            case .unknown:
                HTZMusicTool.setNetworkState(state: "none")
                print("无网络")
                break
            case .notReachable:
                HTZMusicTool.setNetworkState(state: "none")
                print("无网络")
                break
            case .reachable(_):
                if manager!.isReachableOnWWAN {
                    HTZMusicTool.setNetworkState(state: "wwan")
                    print("2G,3G,4G...")
                } else if manager!.isReachableOnEthernetOrWiFi {
                    HTZMusicTool.setNetworkState(state: "wifi")
                    print("wifi")
                }
                break
            }
            // 发送网络状态改变的通知
            NotificationCenter.default.post(name: NSNotification.Name(kNetworkChangeNotification), object: nil)
        }
        
        manager?.startListening()
    }
    
//    private func pgyerCrash() {
//        // 启动基本SDK
//        PgyManager.shared()?.start(withAppId: "f87f93f5acb6b5363c23b8d208324857")
//        // 启动更新检查SDK
//        PgyUpdateManager.sharedPgy()?.start(withAppId: "f87f93f5acb6b5363c23b8d208324857")
//    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "htz")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

