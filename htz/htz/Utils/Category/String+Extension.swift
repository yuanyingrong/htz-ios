//
//  String+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

extension String {
    static func UUID() -> String {
        let uuidRef = CFUUIDCreate(nil)
        let uuidStringRef = CFUUIDCreateString(nil, uuidRef)
        return uuidStringRef! as String
    }
}

extension String {
    //截取第一个到任意位置
    //parameter end 结束的位置
    //Returns: 截取后的字符串
    func stringCut(end: Int) -> String {
        print(self.count)
        if !(end < self.count) {
            return "截取超出范围"
        }
        let sInde = self.index(startIndex, offsetBy: end)
        return String(self[..<sInde])
    }
}

// 下标截取任意位置的便捷方法
extension String {
    
    var length: Int {
        return self.count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)), upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
}

//不包含后几个字符串的方法
//extension String {
//    func dropLast(_ n: Int = 1) -> String {
//        return String(dropLast(n))
//    }
//    var dropLast: String {
//        return dropLast()
//    }
//}
