//
//  HTZAlbumModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZAlbumModel: HandyJSON {
    
    // 图片
    var icon: String?
    
    // 专辑名称
    var title: String?
    
    //
    var desc: String?

    //
    var playcount: String?
    
    //
    var item_total: String?
    
    //
    var time: String?
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.desc <-- "description"
    }
    
    /**
     {
     "icon": "zhongyong",
     "title": "中庸",
     "description": "《中庸》是一篇论述儒家人性修养的散文，原是《礼记》第三十一篇，相传为子思所作，是一部儒家学说经典论著。经北宋程颢、程颐极力尊崇，南宋朱熹作《中庸集注》，最终和《大学》、《论语》、《孟子》并称为“四书”。宋、元以后，《中庸》成为学校官定的教科书和科举考试的必读书，对中国古代教育产生了极大的影响。",
     "playcount": "999",
     "item_total": "80",
     "time": "Sun Aug 25 08:05:25 GMT+08:00 2019"
     }
     */
}
