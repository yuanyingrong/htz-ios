//
//  HTZSaveDataModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/20.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZSaveDataModel: NSObject, NSCoding {
    
    var albumID: String?
    
    var albumIcon: String?
    
    var albumTitle: String?
    
    var fileCount: String? {
        return "\(files?.count ?? 0)"
    }
    
    var fileSizeCount: String? {
        guard let files = files else { return "" }
        var size: CUnsignedLongLong = 0
        for model in files {
            size += kDownloadManager.fileSizeWithFileLocalPath(fileLocalPath: model.song_localPath ?? "")
        }
        return "\(size)"
    }
    
    var files: [HTZMusicModel]?
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(albumID, forKey: "albumID")
        aCoder.encode(albumIcon, forKey: "albumIcon")
        aCoder.encode(albumTitle, forKey: "albumTitle")
        aCoder.encode(fileCount, forKey: "fileCount")
        aCoder.encode(fileSizeCount, forKey: "fileSizeCount")
        aCoder.encode(files, forKey: "files")
    }
    
    required override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        albumID = aDecoder.decodeObject(forKey: "albumID") as? String
        albumIcon = aDecoder.decodeObject(forKey: "albumIcon") as? String
        albumTitle = aDecoder.decodeObject(forKey: "albumTitle") as? String
//        fileCount = aDecoder.decodeObject(forKey: "fileCount") as? String
//        fileSizeCount = aDecoder.decodeObject(forKey: "fileSizeCount") as? String
        files = aDecoder.decodeObject(forKey: "files") as? [HTZMusicModel]
    }
    

    
}
