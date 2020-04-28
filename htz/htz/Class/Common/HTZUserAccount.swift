//
//  HTZUserAccount.swift
//  htz
//
//  Created by 袁应荣 on 2020/3/10.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZUserAccount: NSObject {
    
    @objc var token: String?
    @objc var name: String?
    @objc var id: String?
    @objc var union_id: String?
    @objc var mobile: String?
    @objc var gender: String?
    @objc var created_at: String?
    @objc var avatar: String?
    @objc var birthday_year: String?
    @objc var unionid: String?
    @objc var country: String?
    @objc var province: String?
    @objc var city: String?
    @objc var privilege: [String]?
    @objc var sex: String?
    @objc var nickname: String?
    @objc var openid: String?
    @objc var headimgurl: String?
    
    static let shared = HTZUserAccount()
    
    override init() {
        super.init()
        readUserAccountInfo()
    }

    func saveUserAcountInfoWithDict(dict: [String : Any]) {
        setValuesForKeys(dict)
        UserDefaults.Standard.set(dict, forKey: UserDefaults.keyUserAccount)
    }
    
    func readUserAccountInfo() {
       let obj = UserDefaults.Standard.value(forKey: UserDefaults.keyUserAccount)
        if let obj = obj {
            setValuesForKeys(obj as! [String : Any])
        }
    }
    
    func update(key: String, value: Any) {
        let dict = UserDefaults.Standard.value(forKey: UserDefaults.keyUserAccount)
        if let dict = dict {
            var dic = dict as! [String : Any]
            dic[key] = value
            saveUserAcountInfoWithDict(dict: dic)
        }
    }
    
    
    // 异常处理
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
}
