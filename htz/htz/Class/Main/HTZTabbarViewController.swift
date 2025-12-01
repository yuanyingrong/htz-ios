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
            guard let type = dict["type"] as? String else {
                continue
            }

            if type == "play" {
                // Create a generic UIViewController for the placeholder
                let vc = UIViewController()
                vc.tabBarItem.title = "" // Empty title
                // Use a clear image for the placeholder to occupy space without showing anything
                vc.tabBarItem.image = UIImage()
                vc.tabBarItem.selectedImage = UIImage()
                vc.tabBarItem.tag = 100 // Assign a tag to identify the play item
                let navVC = HTZNavigationController.init(rootViewController: vc)
                addChild(navVC)
            } else {
                guard let title = dict["title"] as? String else {
                    continue
                }
                guard let imageName = dict["normal_icon"] as? String else {
                    continue
                }
                addChildViewController(vcName: vcName, title: title, imageName: imageName)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let playButton = UIButton(type: .custom)

        // Find the view of the middle tab bar item (the placeholder)
        if let middleTabBarItem = self.tabBar.items?[2], // Index 2 for the middle item (0-indexed)
           let middleItemView = middleTabBarItem.value(forKey: "view") as? UIView { // Accessing internal view for positioning
            playButton.frame = middleItemView.bounds
            playButton.center = middleItemView.center // Center relative to the middle item's view
        } else {
            // Fallback if middle item is not found (shouldn't happen with 5 items)
            // This fallback uses the old problematic calculation, but it's unlikely to be hit now
            playButton.frame = CGRect(x: 0, y: 0, width: self.tabBar.bounds.size.width / 5, height: self.tabBar.bounds.size.height)
            playButton.center = CGPoint(x: self.tabBar.centerX, y: self.tabBar.bounds.size.height * 0.3)
        }

        playButton.setImage(UIImage(named: "play_normal"), for: UIControl.State.normal)
        playButton.setImage(UIImage(named: "play_normal"), for: UIControl.State.highlighted)
        playButton.addTarget(self, action: #selector(playButtonClickAction), for: UIControl.Event.touchUpInside)
        self.tabBar.addSubview(playButton)
    }

    @objc func playButtonClickAction() {
        if HTZMusicTool.musicList() != nil {
            let nav = UINavigationController(rootViewController: HTZPlayViewController.sharedInstance)
            HTZPlayViewController.sharedInstance.playMusic()
            nav.modalPresentationStyle = .fullScreen
            HTZMusicTool.visibleViewController()?.present(nav, animated: true, completion: nil)
        } else {
            HTZMusicTool.visibleViewController()?.alert(message: "暂无播放内容")
        }
    }

    func addChildViewController(vcName: String, title: String, imageName: String) {
        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let clsName = namespace + "." + vcName

        guard let cls = NSClassFromString(clsName) as? UIViewController.Type else {
            HTZLog.error("HTZTabbarViewController", "Failed to get class for \(vcName)")
            return
        }

        let vc = cls.init()
        vc.title = title // This sets the navigation bar title
        vc.tabBarItem.title = title // Explicitly set tab bar item title

        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.gray], for: UIControl.State.normal)
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.blue], for: UIControl.State.selected)

        // Handle empty imageName for the placeholder item
        if !imageName.isEmpty && imageName != " " {
            vc.tabBarItem.image = UIImage(named: imageName)
            let s = imageName.replacingOccurrences(of: "_normal", with: "")
            vc.tabBarItem.selectedImage = UIImage(named: "\(s)_select")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        } else {
            // For placeholder, set empty image to occupy space without showing anything
            vc.tabBarItem.image = UIImage()
            vc.tabBarItem.selectedImage = UIImage()
        }

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
