//
//  JsonHelper.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

/**
 * 将Json字符串转为Dictionary或者Array对象
 */

func toJsonObject(_ object:String) -> Any {
    guard let jsonData = object.data(using:String.Encoding.utf8) else {
        return   NSNull()
    }
    do {
        return try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
    }catch let error {
        print("读取本地数据出现错误！",error)
        return NSNull()
    }
    
}



func fromResource(_ resource:String?,_ ofType:String?,_ isJsonStr:Bool) -> Any {
    let path = Bundle.main.path(forResource: resource, ofType: ofType)
    assert(path != nil)
    
    do {
        let jsonStr = try String.init(contentsOfFile: path!)
        if isJsonStr {
            return jsonStr
        }
        return toJsonObject(jsonStr)
    }catch {
        
    }
    
    return NSNull()
    
}
