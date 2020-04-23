//
//  HTZNotificationsModel.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/20.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZNotificationsModel: HandyJSON {
    
    /// 唯一标识符
    var id: String?
    /// 标题
    var title: String?
    ///
    var msg: String?
    ///
    var created_at: String?
    
    required init() {}
}
