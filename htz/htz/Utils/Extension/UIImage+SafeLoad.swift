//
//  UIImage+SafeLoad.swift
//  htz
//
//  Created by on 2025/11/29.
//

import UIKit

extension UIImage {
    /// 安全加载图片，避免因空字符串导致的崩溃
    /// - Parameter name: 图片名称
    /// - Returns: 图片对象，如果名称为空或图片不存在则返回nil
    static func safeImage(named name: String?) -> UIImage? {
        guard let imageName = name, !imageName.isEmpty else {
            return nil
        }
        return UIImage(named: imageName)
    }
}