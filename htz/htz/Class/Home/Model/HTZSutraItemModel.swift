//
//  HTZSutraItemModel.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/10.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZSutraItemModel: HandyJSON {
    

    /// 唯一标识符
    var id: String?
    /// 专辑id
    var sutra_id: String?
    /// 标题
    var title: String?
    /// 经典简介
    var desc: String?
    ///
    var original_lyric_id: String?
    ///
    var explanation_lyric_id: String?
    ///
    var audio_id: String?
    ///
    var lesson: String?
    /// 总共播放次数
    var played_count: String?
    ///
    var duration: String?
    /// 创建时间
    var created_at: String?
    
    
    var isVideo: Bool?
    
    var audio: String?
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.desc <-- "description"
        
//        mapper <<<
//            self.id <-- "hash"
//        
//        mapper <<<
//        self.played_count <-- "playcount"
//        
//        mapper <<<
//            self.explanation <-- "lyric"

    }
    

/**
 {
   "id": "5e381562cd26ff5fb5c95a5a",
   "sutra_id": "5e381050cd26ff5f17aab239",
   "title": "为何肯为大家吃苦最能养气",
   "description": "为何肯为大家吃苦最能养气",
   "audio_id": "1233",
   "lyric_id": "aaa",
   "lesson": 0,
   "played_count": 0,
   "duration": 0,
   "created_at": 1580733794
 }
 */
}
