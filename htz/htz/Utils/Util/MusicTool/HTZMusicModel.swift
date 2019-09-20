//
//  HTZMusicModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import HandyJSON

class HTZMusicModel: NSObject, HandyJSON, NSCoding {

    /// 歌曲id
    var song_id: String?
    
    /// 歌曲名称
    var song_name: String?
    /// 专辑id
    var album_id: String?
    /// 专辑名称
    var album_title: String?
    /// 演唱者
    var singer: String?
    /// 歌手头像
    var singerIcon: String?
    /// 歌词文件名称
    var lrcName: String?
    var lrclink: String?
    /// 歌曲文件名称
    var fileName: String?
    /// 声音时长
    var file_duration: String?
    /// 声音扩展名
    var file_extension: String?
    /// 声音速率
    var file_bitrate: String?
    /// 声音大小
    var file_size: String?
    /// 声音播放路径
    var file_link: String?
    
    /// 专辑图片
    var icon: String?
    
    // MARK: - 额外的扩展属性
    /// 是否正在播放
//    var isPlaying: Bool?
//    var isLike: Bool?
//    var isDownload: Bool?
//    var song_lyricPath: String?
//    var song_imagePath: String?
//    var song_localPath: String?
    
    var isPlaying: Bool? {
        let musicInfo = HTZMusicTool.lastMusicInfo()
        return self.song_id == (musicInfo?["play_id"] as? String)
    }
    
    /// 是否喜欢
    var isLove: Bool?
    var isLike: Bool? {
        var exist = false
        if let lovedMusicList = HTZMusicTool.lovedMusicList() {
            for model in lovedMusicList {
                for music in model.files! {
                    if music.song_id == self.song_id {
                        exist = true
                    }
                }
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
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.song_id <-- "hash"
    }
    
    required override init() {
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(song_id, forKey: "song_id")
        aCoder.encode(song_name, forKey: "song_name")
        aCoder.encode(singer, forKey: "singer")
        aCoder.encode(album_id, forKey: "album_id")
        aCoder.encode(album_title, forKey: "album_title")
        aCoder.encode(singerIcon, forKey: "singerIcon")
        aCoder.encode(lrcName, forKey: "lrcName")
        aCoder.encode(icon, forKey: "icon")
        aCoder.encode(fileName, forKey: "fileName")
        aCoder.encode(lrclink, forKey: "lrclink")
        aCoder.encode(file_duration, forKey: "file_duration")
        aCoder.encode(file_extension, forKey: "file_extension")
        aCoder.encode(file_bitrate, forKey: "file_bitrate")
        aCoder.encode(file_size, forKey: "file_size")
        aCoder.encode(file_link, forKey: "file_link")
        
        aCoder.encode(isPlaying, forKey: "isPlaying")
        aCoder.encode(isLove, forKey: "isLove")
        aCoder.encode(isLike, forKey: "isLike")
        aCoder.encode(isDownload, forKey: "isDownload")
//        aCoder.encode(downloadState, forKey: "downloadState")
        aCoder.encode(song_size, forKey: "song_size")
        aCoder.encode(completed_size, forKey: "completed_size")
        aCoder.encode(progress, forKey: "progress")
        aCoder.encode(fileLength, forKey: "fileLength")
        aCoder.encode(currentLength, forKey: "currentLength")
        
        aCoder.encode(song_localPath, forKey: "song_localPath")
        aCoder.encode(song_lyricPath, forKey: "song_lyricPath")
        aCoder.encode(song_imagePath, forKey: "song_imagePath")
    }
    
    required init?(coder aDecoder: NSCoder) {
        song_id = aDecoder.decodeObject(forKey: "song_id") as? String
        song_name = aDecoder.decodeObject(forKey: "song_name") as? String
        singer = aDecoder.decodeObject(forKey: "singer") as? String
        album_id = aDecoder.decodeObject(forKey: "album_id") as? String
        album_title = aDecoder.decodeObject(forKey: "album_title") as? String
        singerIcon = aDecoder.decodeObject(forKey: "singerIcon") as? String
        lrcName = aDecoder.decodeObject(forKey: "lrcName") as? String
        icon = aDecoder.decodeObject(forKey: "icon") as? String
        fileName = aDecoder.decodeObject(forKey: "fileName") as? String
        lrclink = aDecoder.decodeObject(forKey: "lrclink") as? String
        file_duration = aDecoder.decodeObject(forKey: "file_duration") as? String
        file_extension = aDecoder.decodeObject(forKey: "file_extension") as? String
        file_bitrate = aDecoder.decodeObject(forKey: "file_bitrate") as? String
        file_size = aDecoder.decodeObject(forKey: "file_size") as? String
        file_link = aDecoder.decodeObject(forKey: "file_link") as? String
        
        isLove = aDecoder.decodeObject(forKey: "isLove") as? Bool
        
//        downloadState = aDecoder.decodeObject(forKey: "downloadState") as? HTZDownloadManagerState
        song_size = aDecoder.decodeObject(forKey: "song_size") as? String
        completed_size = aDecoder.decodeObject(forKey: "completed_size") as? String
        progress = aDecoder.decodeObject(forKey: "progress") as? Float
        fileLength = aDecoder.decodeObject(forKey: "fileLength") as? NSInteger
        currentLength = aDecoder.decodeObject(forKey: "currentLength") as? NSInteger
        
//        isLike = aDecoder.decodeObject(forKey: "isLike") as? Bool
//        isDownload = aDecoder.decodeObject(forKey: "isDownload") as? Bool
//        song_localPath = aDecoder.decodeObject(forKey: "song_localPath") as? String
//        song_lyricPath = aDecoder.decodeObject(forKey: "song_lyricPath") as? String
//        song_imagePath = aDecoder.decodeObject(forKey: "song_imagePath") as? String
    }
}
