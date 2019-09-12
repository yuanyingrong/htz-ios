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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let playButton = UIButton()
        let count = self.children.count
        // 将按钮的内缩进的宽度减少
        let w = self.tabBar.bounds.size.width / CGFloat(count) - 1
        // CGRectInset 正数内向缩进,负数外向扩展
        playButton.frame = self.tabBar.bounds
        playButton.setImage(UIImage(named: "play_normal"), for: UIControl.State.normal)
        playButton.setImage(UIImage(named: "play_normal"), for: UIControl.State.highlighted)
        playButton.addTarget(self, action: #selector(playButtonClickAction), for: UIControl.Event.touchUpInside)
        playButton.center = CGPoint(x: self.tabBar.centerX, y: self.tabBar.bounds.size.height * 0.5)
        self.tabBar.addSubview(playButton)
    }
    
    @objc func playButtonClickAction() {
        let nav = UINavigationController(rootViewController: HTZPlayViewController.sharedInstance)
        self.present(nav, animated: true, completion: nil)
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
        let s = imageName.replacingOccurrences(of: "_normal", with: "")
        vc.tabBarItem.selectedImage = UIImage(named: "\(s)_select")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
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
