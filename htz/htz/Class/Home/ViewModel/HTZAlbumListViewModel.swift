//
//  HTZAlbumListViewModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZAlbumListViewModel: NSObject {
    
    var dataArr = [HTZSutraItemModel?]()
    
    var dataSongArr = [HTZMusicModel?]()
    
    var icon: String?
    
    var albumTitle: String?
    
    func requestData(sutra_id: String, page_index: Int, callBack: @escaping (Bool, Bool) -> ()) {
            
        NetWorkRequest(API.items(sutra_id: sutra_id, page_index: page_index, page_size: 20)) { (response) -> (Void) in
                if response["code"].rawString() == "200" {
                    let arr = [HTZSutraItemModel].deserialize(from: response["data"].rawString())
                    if let arr = arr {
                        
                        var arrM = [HTZMusicModel]()
                        for model in arr {
                            let obj = HTZMusicModel()
                            obj.song_name = model?.title
                            obj.song_id = model?.audio_id
                            obj.album_id = model?.sutra_id
                            obj.icon = self.icon
                            obj.album_title = self.albumTitle
                            //                        obj.file_link = "http://htzshanghai.top/resources/audios/\(album)/" + model!.audio!
                            //                                            obj.lrclink = model!.original
                            obj.file_link = "\(ossurl)\(model?.audio_id ?? "")"
                            obj.originalLyricId = model?.original_lyric_id
                            obj.explanationLyricId = model?.explanation_lyric_id
                            obj.originalLyricLink = "\(ossurl)\(model?.original_lyric_id ?? "")"
                            obj.explanationLyricLink = "\(ossurl)\(model?.explanation_lyric_id ?? "")"
                            obj.file_duration = model?.duration
                            
                            obj.downloadState = kDownloadManager.checkDownloadState(fileID: obj.song_id!)
                            arrM.append(obj)
                        }
                        if page_index > 0 {
                            for model in arr {
                                self.dataArr.append(model)
                            }
                            for model in arrM {
                                self.dataSongArr.append(model)
                            }
                        } else {
                            self.dataArr = arr
                            self.dataSongArr = arrM
                        }
                        if arr.count > 0 {
                            // 还可以加载更多
                             callBack(true, false)
                        } else {
                            // 没有更多数据
                             callBack(true, true)
                        }
                        
                    }
                    
                }
                
            }
        }
    func requestData(index: NSInteger, isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
        var target: API = API.xingfuneixinchan
        var album = "xingfuneixinchan"
        if index == 0 {
            target = API.mixinxiaoshipin
            album = "mixinxiaoshipin"
//            var arrM = [HTZMusicModel]()
//            let arr = ["[2019-05-21]_001.mp4", "[2019-05-22]_002.mp4", "[2019-05-23]_003.mp4", "[2019-05-24]_004.mp4", "[2019-05-25]-005.mp4", "[2019-05-28]-007.mp4", "[2019-05-30]-009.mp4", "[2019-05-31]-010.mp4", "[2019-06-01]-011.mp4", "[2019-06-03]-013.mp4", "[2019-06-04]-014.mp4", "[2019-06-05]-015.mp4", "[2019-06-06]-016.mp4", "[2019-06-07]-017.mp4"]
//            for str in arr {
//                let obj = HTZMusicModel()
//                obj.song_name = str
//                obj.song_id = str
//                obj.album_id = self.icon
//                obj.icon = self.icon
//                obj.album_title = self.albumTitle
//                obj.file_link = "http://htzshanghai.top/resources/videos/\(album)/" + obj.song_name!
//
//                obj.downloadState = kDownloadManager.checkDownloadState(fileID: obj.song_id!)
//                arrM.append(obj)
//                let model = HTZAlbumPartModel()
//                model.playcount = "0"
//                self.dataArr.append(model)
//            }
//            self.dataSongArr = arrM
//            callBack(true)
//            return
        } else if index == 1 {
            target = API.xingfuneixinchan
            album = "xingfuneixinchan"
        } else if index == 2  {
            target = API.jingxinyangsheng
            album = "jingxinyangsheng"
        }

        NetWorkRequest(target) { (response) -> (Void) in

            let arr = [HTZSutraItemModel].deserialize(from: response["sutra_items"].rawString())
            if let arr = arr {
                self.dataArr = arr
                var arrM = [HTZMusicModel]()
                for model in arr {
                    let obj = HTZMusicModel()
                    obj.song_name = model?.title
                    obj.song_id = model?.id
                    obj.album_id = self.icon
                    obj.icon = self.icon
                    obj.album_title = self.albumTitle
                    obj.file_link = "http://htzshanghai.top/resources/audios/\(album)/" + model!.audio!
                    obj.originalLyricId = model?.original_lyric_id
                    obj.explanationLyricId = model?.explanation_lyric_id
                    obj.originalLyricLink = "http://htzshanghai.top/resources/lyrics/\(album)/" + model!.original_lyric_id!
                    obj.explanationLyricLink = "http://htzshanghai.top/resources/lyrics/\(album)/" + model!.explanation_lyric_id!
                    obj.file_duration = model?.duration

                    obj.downloadState = kDownloadManager.checkDownloadState(fileID: obj.song_id!)
                    arrM.append(obj)
                }
                self.dataSongArr = arrM
                callBack(true)
            }
            let videos = [HTZVideoModel].deserialize(from: response["videos"].rawString())
            if let videos = videos {

                var arrM = [HTZMusicModel]()
                for model in videos {
                    let obj = HTZMusicModel()
                    obj.song_name = model?.content
                    obj.song_id = model?.videoUrl
                    obj.album_id = self.icon
                    obj.icon = self.icon
                    obj.album_title = model?.title
                    obj.file_link = "http://htzshanghai.top/resources/videos/" + model!.videoUrl!
                    obj.icon = "http://htzshanghai.top/resources/videos/" + model!.coverUrl!

                    arrM.append(obj)

//                    let m = HTZAlbumPartModel()
                    let m = HTZSutraItemModel()
                    m.title = model?.content
                    m.isVideo = true
                    m.played_count = "0"
                    self.dataArr.append(m)
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
