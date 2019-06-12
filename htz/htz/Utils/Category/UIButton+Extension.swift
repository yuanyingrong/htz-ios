//
//  UIButton+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit


extension UIButton {
    /**
     创建button
     @param setImage: 默认状态图片
     @param setBackgroundImage：背景图片
     @param target： target
     @param action： action
     @return
     */
    convenience init(setImage:String,setBackgroundImage:String,target:Any?,action:Selector) {
        self.init()
        self.setImage(UIImage(named:setImage), for: UIControl.State.normal)
        self.setImage(UIImage(named:"\(setImage)_highighted"), for: UIControl.State.highlighted)
        self.setBackgroundImage(UIImage(named:setBackgroundImage), for: UIControl.State.normal)
        self.setBackgroundImage(UIImage(named:"\(setBackgroundImage)_highlighted"), for: UIControl.State.highlighted)
        self.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        self.sizeToFit()
    }
    
    /// 返回带文字的图片的按钮
    ///
    /// - parameter setHighlightImage: 背景图片
    /// - parameter title:             文字
    /// - parameter target:            target
    /// - parameter action:            action
    ///
    /// - returns:
    convenience init(setHighlightImage:String?,title:String?,target:Any?,action:Selector ){
        //        let Btn = UIButton()
        self.init()
        
        if let img = setHighlightImage {
            self.setImage(UIImage(named:img), for: UIControl.State.normal)
            
            self.setImage(UIImage(named:"\(img)_highlighted"), for: UIControl.State.highlighted)
        }
        
        if let tit = title {
            self.setTitle(tit, for: UIControl.State.normal)
            self.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
            self.setTitleColor(UIColor.yellow, for: UIControl.State.highlighted)
            self.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        }
        self.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        
        self.sizeToFit()
        
    }
    
    convenience init(BackgroundImage:String?,title:String?,titleColor:UIColor, target:Any?,action:Selector ){
        
        self.init()
        
        self.setBackgroundImage(UIImage(named:BackgroundImage!), for: UIControl.State.normal)
        self.setTitle(title, for: UIControl.State.normal)
        self.setTitleColor(titleColor, for: UIControl.State.normal)
        
        self.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        
        self.sizeToFit()
        
    }
}
