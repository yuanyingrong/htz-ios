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
    var original: String?
    ///
    var explanation_lyric_id: String?
    ///
    var explanation: String?
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
        
        mapper <<<
            self.id <-- "hash"
        
        mapper <<<
        self.played_count <-- "playcount"
        
        mapper <<<
            self.explanation <-- "lyric"

    }
    

/**
 {
   "id": "5e381562cd26ff5fb5c95a5a",
   "sutra_id": "5e381050cd26ff5f17aab239",
   "title": "为何肯为大家吃苦最能养气",
   "description": "为何肯为大家吃苦最能养气",
   "original": "简介：黄庭禅（即内心禅，微信：黄庭禅），让人们认清世界的乱源只在胸中一方寸上演而已，引导众生找回内心的家，教导社会大众安心之道，望能净化人心，让每个人都能找回本自俱有的那份幸福与自在!",
   "explanation": "本集讲解《礼运大同篇》“男有分，女有归。货恶其弃于地也不必藏于己，力恶其不出于身也不必为己。”为何说想要公平先要安于本分？一个人凭借自己的实力囤积财富会伤生吗？为何说为大家多做劳苦之事有很大的价值和益处？为远离虚名的陷阱应有怎样的心态？且听解答。",
   "audio_id": "1233",
   "lyric_id": "aaa",
   "lesson": 0,
   "played_count": 0,
   "duration": 0,
   "created_at": 1580733794
 }
 */
}
