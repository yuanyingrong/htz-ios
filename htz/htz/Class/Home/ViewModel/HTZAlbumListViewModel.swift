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
    
    func requestData(target: API, isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
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
                    obj.file_link = "http://htzshanghai.top/resources/audios/xingfuneixinchan/" + model!.audio!
                    obj.lrclink = "http://htzshanghai.top/resources/lyrics/xingfuneixinchan/" + model!.lyric!
                    obj.file_duration = model?.duration
                    obj.downloadState = HTZDownloadManagerState.none
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
