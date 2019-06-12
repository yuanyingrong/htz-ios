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