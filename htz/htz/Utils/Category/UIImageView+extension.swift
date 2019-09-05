//
//  UIImageView+extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/2.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import Kingfisher

extension UIImageView {
    
    /// 传imageName初始化一个imageView
    ///
    /// - Parameter imageName: 图片的名字
    convenience init(imageName: String) {
        self.init()
        self.image = UIImage(named: imageName)
    }
}

extension UIImageView {
    func wb_setImageWith(urlStr: String, placeHolder: String? = nil) {
        if let url = URL(string: urlStr) {
            
            if let placeHolder = placeHolder {
                kf.setImage(with: url, placeholder: UIImage(named: placeHolder))
            } else {
                kf.setImage(with: url)
            }
        }
    }
}
