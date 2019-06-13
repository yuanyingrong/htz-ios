//
//  UIBarButtonItem+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem {
    convenience init(setHighlightedImg:String?, title:String?,target:Any?,action:Selector) {
        self.init()
        let button = UIButton(setHighlightImage:setHighlightedImg, title: title, target: target, action: action)
        self.customView = button
    }
}
