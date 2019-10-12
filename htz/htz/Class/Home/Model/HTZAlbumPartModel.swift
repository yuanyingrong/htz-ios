//
//  HTZAlbumPartModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZAlbumPartModel: HandyJSON {
    
    // 标题
    var title: String?
    
    //
    var desc: String?
    
    //
    var original: String?
    
    //
    var audio: String?
    
    //
    var lyric: String?
    
    //
    var lesson: String?
    
    //
    var playcount: String?
    
    //
    var duration: String?
    
    //
    var hash: String?
    
    //
    var time: String?
    
    var isVideo: Bool?
    
    required init() {}
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.desc <-- "description"
    }
    
    /**
     {
     "title": "002.烦劳的来源",
     "description": "",
     "original": "",
     "audio": "radio-02-20130118.mp3",
     "lyric": "",
     "lesson": "2",
     "playcount": "1",
     "duration": "123123",
     "hash": "d41d8cd98f00b204e9800998ecf8002",
     "time": "Sun Aug 25 08:05:25 GMT+08:00 2019"
     }
     */
}
