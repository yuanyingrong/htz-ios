//
//  HTZDownloadModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

@objc enum HTZDownloadManagerState: NSInteger {
    case none          = 0    // 未开始
    case waiting       = 1    // 等待下载
    case downloading   = 2    // 下载中
    case paused        = 3    // 下载暂停
    case failed        = 4    // 下载失败
    case finished      = 5    // 下载完成
}

class HTZDownloadModel: NSObject, NSCoding {
    
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
        
        return kDownloadManager.downloadDataDir() + "/" + fileID! + "." + fileFormat!
    }
    var fileLyricPath: String {
        return kDownloadManager.downloadDataDir() + "/" + fileID! + ".lrc"
    }
    var fileImagePath: String {
        return kDownloadManager.downloadDataDir() + "/" + fileID! + ".jpg"
    }
    var file_size: String?
    var state: HTZDownloadManagerState?
    /// 文件的总长度
    var fileLength: NSInteger?
    /// 当前的下载长度
    var currentLength: NSInteger?
    
    required override init() {
        super.init()
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fileID, forKey: "fileID")
        aCoder.encode(fileName, forKey: "fileName")
        aCoder.encode(fileUrl, forKey: "fileUrl")
        aCoder.encode(fileLyric, forKey: "fileLyric")
        aCoder.encode(state?.rawValue, forKey: "state")
        aCoder.encode(fileDuration, forKey: "fileDuration")
        aCoder.encode(fileFormat, forKey: "fileFormat")
        aCoder.encode(fileArtistName, forKey: "fileArtistName")
        aCoder.encode(fileSize, forKey: "fileSize")
        aCoder.encode(file_size, forKey: "file_size")
        aCoder.encode(fileLength, forKey: "fileLength")
        aCoder.encode(currentLength, forKey: "currentLength")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fileID = aDecoder.decodeObject(forKey: "fileID") as? String
        fileName = aDecoder.decodeObject(forKey: "fileName") as? String
        fileUrl = aDecoder.decodeObject(forKey: "fileUrl") as? String
        fileLyric = aDecoder.decodeObject(forKey: "fileLyric") as? String
        fileDuration = aDecoder.decodeObject(forKey: "fileDuration") as? String
        fileFormat = aDecoder.decodeObject(forKey: "fileFormat") as? String
        fileArtistName = aDecoder.decodeObject(forKey: "fileArtistName") as? String
        fileSize = aDecoder.decodeObject(forKey: "fileSize") as? String
        file_size = aDecoder.decodeObject(forKey: "file_size") as? String
        fileLength = aDecoder.decodeObject(forKey: "fileLength") as? NSInteger
        currentLength = aDecoder.decodeObject(forKey: "currentLength") as? NSInteger
        if let str = aDecoder.decodeObject(forKey: "state") {
            state = HTZDownloadManagerState(rawValue: str as! NSInteger)
        }
        
    }
}
