//
//  HTZMusicMessageModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZMusicMessageModel: NSObject {

    /// 音乐数据
    var musicModel: HTZMusicModel?
    
    /// 当前播放时长
    var costTime: TimeInterval?
    
    /// 歌曲总时长
    var totalTime: TimeInterval?
    
    /// 当前播放状态
    var playing: Bool?
    
    /// 当前播放时长 字符串格式
    var costTimeFormat: String?
    
    /// 歌曲总时长 字符串格式
    var totalTimeFormat: String?
}
