//
//  HTZMusicModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZMusicModel: HandyJSON {

    /// 歌曲id
    var song_id: String?
    
    /// 歌曲名称
    var name: String?
    
    /// 演唱者
    var singer: String?
    
    /// 歌手头像
    var singerIcon: String?
    
    /// 歌词文件名称
    var lrcName: String?
    
    /// 歌曲文件名称
    var fileName: String?
    
    /// 专辑图片
    var icon: String?
    
    
    /// 是否正在播放
    var isPlaying: Bool {
        let musicInfo = HTZMusicTool.lastMusicInfo()
        return self.song_id == (musicInfo!["play_id"] as! String)
    }
    
    /// 是否喜欢
    var isLove: Bool?
    var isLike: Bool {
        var exist = false
        for model in HTZMusicTool.lovedMusicList() {
            if model.song_id == self.song_id {
                exist = true
            }
        }
        return exist
    }
    
    /// 是否下载
    var isDownload: Bool {
        return kDownloadManager.checkDownloadWithID(fileID: self.song_id!)
    }
    
    var downloadState: HTZDownloadManagerState?
    
    var song_size: String?
    var completed_size: String?
    
    var progress: Float?
    var fileLength: NSInteger?
    var currentLength: NSInteger?
    
    /// 歌曲的本地路径
    var song_localPath: String? {
        if let song_id = self.song_id, self.isDownload {
            return kDownloadManager.modelWithID(fileID: song_id)?.fileLocalPath
        }
        return nil
    }
    
    /// 歌曲的本地歌词
    var song_lyricPath: String? {
        if let song_id = self.song_id, self.isDownload {
            return kDownloadManager.modelWithID(fileID: song_id)?.fileLyricPath
        }
        return nil
    }
    
    /// 歌曲的本地图片
    var song_imagePath: String? {
        if let song_id = self.song_id, self.isDownload {
            return kDownloadManager.modelWithID(fileID: song_id)?.fileImagePath
        }
        return nil
    }
    
    required init() {}
}
