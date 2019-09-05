//
//  UIButton+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

//MARK: 定义button相对label的位置
extension UIButton {
    
    @objc func set(image anImage: UIImage?, title: String,
                   titlePosition: UIView.ContentMode, additionalSpacing: CGFloat, state: UIControl.State){
//        self.imageView?.contentMode = .left
        self.setImage(anImage, for: state)
        
        positionLabelRespectToImage(title: title, position: titlePosition, spacing: additionalSpacing)
        
        self.titleLabel?.contentMode = .center
        self.setTitle(title, for: state)
        titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.setTitleColor(UIColor.red, for: state)
    }
    
    private func positionLabelRespectToImage(title: String, position: UIView.ContentMode,
                                             spacing: CGFloat) {
        let imageSize = self.imageRect(forContentRect: self.frame)
        let titleFont = self.titleLabel?.font!
        let titleSize = title.size(withAttributes: [NSAttributedString.Key.font: titleFont!])
        
        var titleInsets: UIEdgeInsets
        var imageInsets: UIEdgeInsets
        
        switch (position){
        case .top:
            titleInsets = UIEdgeInsets(top: -(imageSize.height + titleSize.height + spacing),
                                       left: -(imageSize.width), bottom: 0, right: 0)
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -titleSize.width)
        case .bottom:
            titleInsets = UIEdgeInsets(top: (imageSize.height + titleSize.height + spacing),
                                       left: -(imageSize.width), bottom: 0, right: 0)
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        case .left:
            titleInsets = UIEdgeInsets(top: 0, left: -(imageSize.width * 2), bottom: 0, right: 0)
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0,
                                       right: -(titleSize.width * 2 + spacing))
        case .right:
            titleInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -spacing)
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        default:
            titleInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        self.titleEdgeInsets = titleInsets
        self.imageEdgeInsets = imageInsets
    }
}

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
    
    convenience init (title: String?, fontSize: CGFloat = 13, color: UIColor = UIColor.darkGray, image: String? = nil, bgImage: String? = nil, target: Any? = nil, selector: Selector? = nil, event: UIControl.Event = .touchUpInside) {
        
        self.init()
        
        //设置title
        if let title = title {
            self.setTitle(title, for: .normal)
            self.setTitleColor(color, for: .normal)
            self.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        }
        
        // 设置图片
        if let image = image {
            self.setImage(UIImage(named: image), for: .normal)
            self.setImage(UIImage(named: "\(image)_highlighted"), for: .highlighted)
        }
        
        // 设置背景图片
        if let bgImage = bgImage {
            self.setBackgroundImage(UIImage(named: bgImage), for: .normal)
            self.setBackgroundImage(UIImage(named: "\(bgImage)_highlighted"), for: .highlighted)
        }
        
        // 给button加点击事件
        if let target = target, let selector = selector {
            self.addTarget(target, action: selector, for: event)
        }
    }
}
