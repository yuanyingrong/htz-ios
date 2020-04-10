//
//  HTZSutraInfoModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZSutraInfoModel: HandyJSON {
    
    
    /// 唯一标识符
    var id: String?
    /// 经典名称
    var name: String?
    /// 封面文件ID
    var cover: String?
    /// 经典简介
    var desc: String?
    /// 总共播放次数
    var played_count: String?
    /// 一共有多少集
    var item_total: String?
    /// 创建时间
    var created_at: String?
    
    ///
    var time: String?
    
    var index: NSInteger?
    
    var isVideo: Bool?
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            
            self.desc <-- "description"
    }
    
    /**
     {
       "cover" : "tests\/5e8b26f1e2e76d070697e28b",
       "played_count" : 0,
       "description" : "黄庭禅创办人张庆祥如此说 ：幸福在哪里? 幸福就在你心里!只要能从内心感觉到自己很幸福,不论目前的境遇,你便能享有真正的幸福快乐!怎样才能有幸福的感觉?古圣先贤已把方法归纳为「心理、 生理、事理」，若这三个方向都圆满~幸福~就这么简单！",
       "id" : "5e8b26f1e2e76d0d7b0c7eec",
       "item_total" : 1,
       "name" : "幸福内心禅",
       "created_at" : 1586177777
     }
     */
}
