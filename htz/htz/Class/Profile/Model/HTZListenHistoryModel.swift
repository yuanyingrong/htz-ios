//
//  HTZListenHistoryModel.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/20.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZListenHistoryModel: HandyJSON {
    
    /// 唯一标识符
    var id: String?
    /// 经典唯一标识符
    var sutra_id: String?
    /// 经典名称
    var sutra_name: String?
    /// 经典专辑封面文件id
    var sutra_cover: String?
    /// 经典专辑条目id
    var sutra_item_id: String?
    /// 经典专辑条目标题
    var sutra_item_title: String?
    /// 上次听到哪里，单位：秒。小于零表示已经听完。
    var last_position: String?
    ///
    var user_id: String?
    ///
    var created_at: String?
    
    required init() {}
    

}
