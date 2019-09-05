//
//  HTZDownloadModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

enum HTZDownloadManagerState: NSInteger {
    case none          = 0    // 未开始
    case waiting       = 1    // 等待下载
    case downloading   = 2    // 下载中
    case paused        = 3    // 下载暂停
    case failed        = 4    // 下载失败
    case finished      = 5    // 下载完成
}

class HTZDownloadModel: NSObject {

    var fileID: String?
    var fileName: String?
    var fileArtistId: String?
    var fileArtistName: String?
    var fileAlbumId: String?
    var fileAlbumName: String?
    var fileCover: String?
    var fileUrl: String?
    var fileDuration: String?
    var fileFormat: String?
    var fileRate: String?
    var fileSize: String?
    var fileLyric: String?
    var fileLocalPath: String {
        return kDownloadManager.downloadDataDir().appending("\(String(describing: fileID)).\(String(describing: fileFormat))")
    }
    var fileLyricPath: String {
        return kDownloadManager.downloadDataDir().appending("\(String(describing: fileID)).lrc")
    }
    var fileImagePath: String {
        return kDownloadManager.downloadDataDir().appending("\(String(describing: fileID)).jpg")
    }
    var file_size: String?
    var state: HTZDownloadManagerState?
    /// 文件的总长度
    var fileLength: NSInteger?
    /// 当前的下载长度
    var currentLength: NSInteger?
    
}
