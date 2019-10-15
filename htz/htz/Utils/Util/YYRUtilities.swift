//
//  YYRUtilities.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/15.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class YYRUtilities: NSObject {
    
    static func image(color: UIColor, size: CGSize) -> UIImage? {
        
        if size.width <= 0 || size.height <= 0 {
            return nil
        }
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
