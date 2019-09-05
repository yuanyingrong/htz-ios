//
//  UIImage+extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

extension UIImage {
    static func getNewImage(sourceImage: UIImage, lrcStr: String) -> UIImage {
        // 1.开启图形上下文
        let size = sourceImage.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // 2.绘制大的图片
        sourceImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 3.绘制歌词
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributes = [NSAttributedString.Key.foregroundColor : UIColor.white,NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20),NSAttributedString.Key.paragraphStyle : paragraphStyle]
        
        (lrcStr as NSString).draw(in: CGRect(x: 0, y: 0, width: size.width, height: 24), withAttributes: attributes)
        
        // 4.获取结果图片
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
         // 5.关闭图形上下文
        UIGraphicsEndImageContext()
        
        // 6.返回结果
        return resultImage!
    }
}
