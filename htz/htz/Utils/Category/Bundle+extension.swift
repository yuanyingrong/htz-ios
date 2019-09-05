//
//  Bundle+extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/2.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

private let oldVersionKey = "oldVersionKey"

// 在swift中, 只有String<->NSString, Array<->NSArray, Dictionary<->NSDictionary, Set<->NSSet, 类型转换可以直接使用as, 其它情况需要使用 as?或者as!
// as?: 转换可能成功, 可能不成功, 如果不成功, 会返回nil. 最终会返回一个可选值
// as!: 假设转换一定可以成功, 如果不成功, 会崩溃

extension Bundle {
    var nameSpace: String {
        return Bundle.main.infoDictionary!["CFBundleName"] as! String
    }
}

// MARK: - 判断是否是新版本
extension Bundle {
    
    class func test() {
        
    }
    
    class func isNewFeature() -> Bool {
        var isNew = false
        //获取当前版本号
        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        //获取老版本号
        let oldVersion = UserDefaults.Standard.value(forKey: oldVersionKey) as? String
        //判断是否是新版本
        isNew = oldVersion == nil ? true : oldVersion! != currentVersion
        //将当前版本号存储
        UserDefaults.Standard.setValue(currentVersion, forKey: oldVersionKey)
        
        return isNew
    }
}
