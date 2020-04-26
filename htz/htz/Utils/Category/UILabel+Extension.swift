//
//  UILabel+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    convenience init (title: String?, fontSize: CGFloat = 13, textColor: UIColor = UIColor.darkGray, alignMent: NSTextAlignment = .left, numOfLines: Int = 0) {
        // 调用指定构造器,保存所有的存储属性被正确初始化
        self.init()
        // 此时对象已创建
        self.text = title
        self.font = UIFont.systemFont(ofSize: fontSize)
        self.textColor = textColor
        self.textAlignment = alignMent
        self.numberOfLines = numOfLines
    }
    
    convenience init(text:String,font:CGFloat,textColor:UIColor,maxWidth:CGFloat = 0) {
        self.init()
        self.text = text
        self.font = UIFont.systemFont(ofSize: font)
        self.textColor = textColor
        self.numberOfLines = 0
        if maxWidth > 0 {
            self.preferredMaxLayoutWidth = maxWidth
        }
    }
    
    class func createLabel(_ frame:CGRect = CGRect.zero,font: UIFont = UIFont.systemFont(ofSize: 14),
                           textColor:UIColor = UIColor.white,
                           textAlignment:NSTextAlignment = .left,
                           text:String = "") -> UILabel {
        let label = UILabel()
        label.frame = frame
        label.font = font
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.text = text
        label.numberOfLines = 0
        return label
    }
}
