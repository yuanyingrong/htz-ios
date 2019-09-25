//
//  HTZAlbumListViewModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZAlbumListViewModel: NSObject {
    
    var dataArr = [HTZAlbumPartModel?]()
    
    var dataSongArr = [HTZMusicModel?]()
    
    var icon: String?
    
    var albumTitle: String?
    
    func requestData(index: NSInteger, isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
        var target: API = API.xingfuneixinchan
        var album = "xingfuneixinchan"
        if index == 0 {
            target = API.xingfuneixinchan
            album = "xingfuneixinchan"
        } else if index == 1  {
            target = API.jingxinyangsheng
            album = "jingxinyangsheng"
        }
        
        NetWorkRequest(target) { (response) -> (Void) in
            
            let arr = [HTZAlbumPartModel].deserialize(from: response["sutra_items"].rawString())
            if let arr = arr {
                self.dataArr = arr
                var arrM = [HTZMusicModel]()
                for model in arr {
                    let obj = HTZMusicModel()
                    obj.song_name = model?.title
                    obj.song_id = model?.hash
                    obj.album_id = self.icon
                    obj.icon = self.icon
                    obj.album_title = self.albumTitle
                    obj.file_link = "http://htzshanghai.top/resources/audios/\(album)/" + model!.audio!
                    obj.lrclink = "http://htzshanghai.top/resources/lyrics/\(album)/" + model!.lyric!
                    obj.file_duration = model?.duration
                    
                    obj.downloadState = kDownloadManager.checkDownloadState(fileID: obj.song_id!)
                    arrM.append(obj)
                }
                self.dataSongArr = arrM
                callBack(true)
            }
            print(response["sutra_items"])
        }
    }
    
    func requestSongData(isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
        NetWorkRequest(API.song(type: "1", size: "20", offset: "1")) { (response) -> (Void) in
            
            let arr = [HTZMusicModel].deserialize(from: response["song_list"].rawString())
            if let arr = arr {
                self.dataSongArr = arr
                callBack(true)
            }
            print(response["song_list"])
        }
    }

}
