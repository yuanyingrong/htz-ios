//
//  HTZTabbarViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

class HTZTabbarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let jsonPath = Bundle.main.path(forResource: "menu", ofType: "json") else {
            return 
        }
//        NSData(contentsOf: URL(fileURLWithPath: StringjsonPath), options: NSData.ReadingOptions.mappedIfSafe)
        guard let jsonData = NSData(contentsOfFile: jsonPath) else { return
        }
        guard let json = try? JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
            return
        }
        
        let anyObject = json as AnyObject
        
        // key 为String，value：Any
        guard let dict = anyObject.self as? [String: Any] else {
            return
        }
        guard let dictArr = dict["tabbar_items"] as? [[String: Any]] else {
            return
        }
        
        for dict in dictArr {
            guard let vcName = dict["page"] as? String else {
                continue
            }
            guard let title = dict["title"] as? String else {
                continue
            }
            guard let imageName = dict["normal_icon"] as? String else {
                continue
            }
            addChildViewController(vcName: vcName, title: title, imageName: imageName)
        }
        
    }
    
    func addChildViewController(vcName: String, title: String, imageName: String) {
        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let clsName = namespace + "." + vcName
        let cls = NSClassFromString(clsName) as! UIViewController.Type
        
        let vc = cls.init()
        vc.title = title
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.gray], for: UIControl.State.normal)
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.blue], for: UIControl.State.selected)
        vc.tabBarItem.image = UIImage(named: imageName)
        vc.tabBarItem.selectedImage = UIImage(named: "\(imageName)_select")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        let navVC = HTZNavigationController.init(rootViewController: vc)
        addChild(navVC)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
