//
//  HTZLoginModel.swift
//  htz
//
//  Created by 袁应荣 on 2020/3/9.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZLoginModel: HandyJSON {

    var token: String?
    var name: String?
    var id: String?
    var union_id: String?
    var mobile: String?
    var gender: String?
    var created_at: String?
    var avatar: String?
    var birthday_year: String?
    var wx_login_resp: wx_login_resp?

    required init() {}
}

class wx_login_resp: HandyJSON {
    
    var country: String?
    var unionid: String?
    var city: [String]?
    var privilege: String?
    var sex: String?
    var province: String?
    var nickname: String?
    var openid: String?
    var headimgurl: String?
    
    required init() {}
}
