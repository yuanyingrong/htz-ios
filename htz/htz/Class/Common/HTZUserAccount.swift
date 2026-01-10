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
    var sex: Int?
    @objc var nickname: String?
    @objc var openid: String?
    @objc var headimgurl: String?
    
    @objc var sign: String?
    
    static let shared: HTZUserAccount = HTZUserAccount()
    
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
            let dict = obj as! [String : Any]
            // 手动赋值而不是使用 setValuesForKeys，避免 KVC 问题
            if let token = dict["token"] as? String { self.token = token }
            if let name = dict["name"] as? String { self.name = name }
            if let nickname = dict["nickname"] as? String { self.nickname = nickname }
            if let headimgurl = dict["headimgurl"] as? String { self.headimgurl = headimgurl }
            if let unionid = dict["unionid"] as? String { self.unionid = unionid }
            if let openid = dict["openid"] as? String { self.openid = openid }
            if let avatar = dict["avatar"] as? String { self.avatar = avatar }
            if let mobile = dict["mobile"] as? String { self.mobile = mobile }
            if let id = dict["id"] as? String { self.id = id }
            if let created_at = dict["created_at"] as? String { self.created_at = created_at }
            if let birthday_year = dict["birthday_year"] as? String { self.birthday_year = birthday_year }
            if let gender = dict["gender"] as? String { self.gender = gender }
            if let province = dict["province"] as? String { self.province = province }
            if let city = dict["city"] as? String { self.city = city }
            if let country = dict["country"] as? String { self.country = country }
            if let privilege = dict["privilege"] as? [String] { self.privilege = privilege }
            if let union_id = dict["union_id"] as? String { self.union_id = union_id }
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
        // 不打印，避免过多 log
    }
}
