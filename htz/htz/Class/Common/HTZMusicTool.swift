//
//  HTZMusicTool.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/10.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

private let kDataPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last?.appending("/audio.json")

private let kLovedDataPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last?.appending("/audio_love.json")

private let kHistoryDataPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last?.appending("/search_history.json")

class HTZMusicTool: NSObject {

    
    /// 此方法用于保存当前正在播放的音乐列表
    ///
    /// - Parameter musicList: 当前正在播放的音乐列表
    static func save(musicList: [HTZMusicModel]) {
        
        NSKeyedArchiver.archiveRootObject(musicList, toFile: kDataPath!)
    }
    
    /// 此方法用于获取本地保存的播放器正在播放的音乐列表
    ///
    /// - Returns: 音乐列表
    static func musicList() -> [HTZMusicModel]? {
        let musics = NSKeyedUnarchiver.unarchiveObject(withFile: kDataPath!)
        if let musics = musics {
            return musics as? [HTZMusicModel] 
        }
        return nil
    }
    
    static func lovedMusicList() -> [HTZSaveDataModel]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: kLovedDataPath!) as? [HTZSaveDataModel]
    }
    
    static func love(music: HTZMusicModel) {
        var saveArr = [HTZSaveDataModel]()
        var saveIndex: Int?
        var arr = [HTZMusicModel]()
        if let lovedMusicList = lovedMusicList() {
            for (idx, obj) in lovedMusicList.enumerated() {
                saveArr = lovedMusicList
                saveIndex = idx
                if obj.albumID == music.album_id {
                    if let files = obj.files {
                        arr = files
                    }
                    break
                }
            }
        }
        if music.isLove! {
            var exist = false
            for obj in arr {
                if obj.song_id == music.song_id {
                    exist = true
                    break
                }
            }
            if !exist {
                arr.append(music)
                if let saveIndex = saveIndex, saveArr[saveIndex].albumID == music.album_id {
                    saveArr[saveIndex].files = arr
                } else {
                    let model = HTZSaveDataModel()
                    model.albumID = music.album_id
                    model.albumTitle = music.album_title
                    model.albumIcon = music.icon
                    model.files = arr
                    saveArr.append(model)
                }
            }
        } else {
            var index = 0
            var exist = false
            for (idx, obj) in arr.enumerated() {
                if obj.song_id == music.song_id {
                    index = idx
                    exist = true
                    break
                }
            }
            if exist {
                arr.remove(at: index)
            }
            if arr.count > 0 {
                saveArr[saveIndex!].files = arr
            } else {
                saveArr.remove(at: saveIndex!)
            }
        }
        NSKeyedArchiver.archiveRootObject(saveArr, toFile: kLovedDataPath!)
    }
    
    static func index(from musicID: String) -> NSInteger {
        var index = 0
        for (idx, obj) in musicList()!.enumerated() {
            if obj.song_id == musicID {
                index = idx
                break
            }
        }
        return index
    }
    
    static func save(model: HTZMusicModel) {
        
        var musics = [HTZMusicModel]()
        if let lovedMusicList = lovedMusicList() {
            for obj in lovedMusicList {
                if obj.albumID == model.album_id {
                    if let files = obj.files {
                        musics = files
                    }
                    break
                }
            }
        }
        for (idx, obj) in musics.enumerated() {
            if obj.song_id == model.song_id {
                musics[idx] = obj
                break
            }
        }
        save(musicList: musics)
    }
    
    static func historys() -> [HTZMusicModel] {
        return NSKeyedUnarchiver.unarchiveObject(withFile: kHistoryDataPath!) as! [HTZMusicModel]
    }
    
    static func save(historys: [HTZMusicModel]) {
        NSKeyedArchiver.archiveRootObject(historys, toFile: kHistoryDataPath!)
    }
    
    static func deleteHistory(index: NSInteger) {
        var arr = historys()
        arr.remove(at: index)
        save(historys: arr)
    }
    
    /// 历史播放信息
    static func lastMusicInfo() -> [String : Any]? {
        return UserDefaults.Standard.object(forKey: UserDefaults.keyPlayInfo) as? [String : Any]
    }
    
    static func playStyle() -> NSInteger {
        return UserDefaults.Standard.integer(forKey: UserDefaults.keyPlayStyle)
    }
    
    static func visibleViewController() -> UIViewController? {
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        return rootVC?.visibleViewControllerIfExist()
    }
    
    static func showPlayBtn() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.palyButton.isHidden = false
    }
    
    static func hidePlayBtn() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.palyButton.isHidden = true
    }
    
    static func networkState() -> String {
        return UserDefaults.Standard.object(forKey: UserDefaults.keyNetworkState) as! String
    }
    
    static func setNetworkState(state: String) {
        UserDefaults.Standard.set(state, forKey: UserDefaults.keyNetworkState)
        UserDefaults.Standard.synchronize()
    }
    
    static func timeStr(msTime: TimeInterval) -> String {
        return timeStr(secTime: msTime / 1000)
    }
    
    static func timeStr(secTime: TimeInterval) -> String {
        let time = NSInteger(secTime)
        if time / 3600 > 0 { // 时分秒
            let hour = time / 3600
            let minute = (time % 3600) / 60
            let second = (time % 3600) % 60
            return String(format: "%02zd:%02zd:%02zd", hour, minute, second)
        } else { // 分秒
            let minute = time / 60
            let second = time % 60
            return String(format: "%02zd:%02zd", minute, second)
        }
    }
    
    static func downloadMusic(songId: String) {
        
        NetWorkRequest(.xingfuneixinchan, completion: { (respose) -> (Void) in
            let dModel = HTZDownloadModel()
            
            kDownloadManager.addDownloadArr(downloadArr: [dModel])
            print("已加入到下载队列")
        }) { (error) -> (Void) in
            print("获取详情失败==\(error)")
            print("加入下载失败")
        }
    }
    
    static func downloadMusic(musicModel: HTZMusicModel) {
        
        let dModel = HTZDownloadModel()
        dModel.fileID = musicModel.song_id
        dModel.fileName = musicModel.song_name
        dModel.fileAlbumId = musicModel.album_id
        dModel.fileAlbumName = musicModel.album_title
        dModel.fileCover = musicModel.icon
        dModel.fileUrl = musicModel.file_link
        dModel.fileDuration = musicModel.file_duration
        dModel.originalLyricId = musicModel.originalLyricId
        dModel.explanationLyricId = musicModel.explanationLyricId
        dModel.originalLyricLink = musicModel.originalLyricLink
        dModel.explanationLyricLink = musicModel.explanationLyricLink
        
//        dModel.fileFormat = "mp3"
//        dModel.fileFormat = musicModel.file_link?.components(separatedBy: ".").last
        
        kDownloadManager.addDownloadArr(downloadArr: [dModel])
        print("已加入到下载队列")
        
    }
}
