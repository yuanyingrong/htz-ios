//
//  UIColor+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {
    
    class func colorWithHexString(_ hex:String) -> UIColor {
        return colorWithHexString(hex, alpha: CGFloat(1.0))
    }
    
    class func colorWithHexString(_ hex:String,alpha: CGFloat) -> UIColor {
        
        var cString = hex.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            let index = cString.index(cString.startIndex, offsetBy:1)
            //            cString = cString.substring(from: index)
            cString = String(cString[index...])
        }
        
        if (cString.count != 6) {
            return UIColor.red
        }
        
        let rIndex = cString.index(cString.startIndex, offsetBy: 2)
        let rString = String(cString[..<rIndex])
        //        let rString = cString.substring(to: rIndex)
        
        let otherString = String(cString[rIndex...])
        //        let otherString = cString.substring(from: rIndex)
        
        let gIndex = otherString.index(otherString.startIndex, offsetBy: 2)
        let gString = String(otherString[..<gIndex])
        //        let gString = otherString.substring(to: gIndex)
        
        let bIndex = cString.index(cString.endIndex, offsetBy: -2)
        
        let bString = String(cString[bIndex...])
        //        let bString = cString.substring(from: bIndex)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}

// with alpha
func RGB(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat) -> UIColor {
    return UIColor.init(red: r, green: g, blue: b, alpha: 1)
}

func RGBA(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat) -> UIColor {
    return UIColor.init(red: r, green: g, blue: b, alpha: a)
}

func RandomColor() -> UIColor {
    // 浅色
    let r = arc4random_uniform(125)
    let g = arc4random_uniform(125)
    let b = arc4random_uniform(125)
    return UIColor.init(red: CGFloat(Double(r)/255.0), green: CGFloat(Double(g)/255.0), blue: CGFloat(Double(b)/255.0), alpha: 0.6)
}
