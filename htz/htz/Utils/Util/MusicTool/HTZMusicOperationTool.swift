//
//  HTZMusicOperationTool.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/3.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import MediaPlayer

class HTZMusicOperationTool: NSObject {

    /// 获取对象单例
    static let sharedInstance = HTZMusicOperationTool()
    
    /// 音乐播放列表
    var musicMList: [HTZMusicModel]?
    
    /// 音乐播放工具
    private lazy var tool: HTZMusicPlayTool = {
        let tool = HTZMusicPlayTool()
        return tool
    }()
    
    /// 当前播放音乐的信息
    private lazy var musicMessageModel: HTZMusicMessageModel = {
        let musicMessageModel = HTZMusicMessageModel()
        return musicMessageModel
    }()
    
    ///  锁屏 所需的图片参数设置
    private var artwork: MPMediaItemArtwork?
    
    /// 记录当前歌曲的歌词 播放到哪一行
    private lazy var lrcRow: NSInteger = {
        let lrcRow = -1
        return lrcRow
    }()

    /// 当前播放音乐的索引
    var index: NSInteger? {
        
        didSet { // 防止越界
            if index! < 0 {
                index = musicMList!.count - 1
            } else if index! > musicMList!.count - 1 {
                index = 0
            }
        }
    }
    
    func getNewMusicMessageModel() -> HTZMusicMessageModel {
         // 更新数据
        musicMessageModel.musicModel = musicMList?[index!]
        // 已经播放的时长
        musicMessageModel.costTime = self.tool.player?.currentTime
        // 总时长
        musicMessageModel.totalTime = self.tool.player?.duration
        // 播放状态
        musicMessageModel.playing = self.tool.player?.isPlaying
        
        return musicMessageModel
    }
}

// MARK: - 单首音乐的操作
extension HTZMusicOperationTool {
    
    func playMusic(music: HTZMusicModel) -> Bool {
        let fileName = music.fileName
        let isPlayMusicSucceed = tool.playMusic(musicName: fileName!)
        if musicMList == nil || musicMList!.count <= 1 {
            print("没有播放列表, 只能播放一首歌")
            return false
        }
        // 记录当前播放歌曲的索引
        let tempArr = musicMList! as NSArray
        index = tempArr.index(of: music)
        return isPlayMusicSucceed
    }
    
    /// 播放当前歌曲
    func playCurrentMusic() {
        tool.resumeCurrentMusic()
    }
    
    /// 暂停当前音乐播放
    func pauseCurrentMusic() {
        tool.pauseCurrentMusic()
    }
    
    /// 停止当前音乐
    func stopCurrentMusic() {
        tool.stopCurrentMusic()
    }
    
    /// 播放 下一首
    func nextMusic() -> Bool {
        index! += 1
        if let musicList = musicMList {
            let music = musicList[index!]
            return playMusic(music: music)
        }
        return false
    }
    
    /// 播放 上一首
    func preMusic() -> Bool {
        index! -= 1
        if let musicList = musicMList {
            let music = musicList[index!]
            return playMusic(music: music)
        }
        return false
    }
    
    
    /// 指定当前播放进度
    ///
    /// - Parameter timeInteval: 歌曲已经播放的时间
    func seekTo(timeInteval: TimeInterval) {
        tool.seekTo(timeInteval: timeInteval)
    }
}


// MARK: - 锁屏信息设置
extension HTZMusicOperationTool {
    
    /// 设置锁屏信息
    func setUpLockMessage() {
        
        // 展示锁屏信息
        let musicMessageModel = getNewMusicMessageModel()
        
        // 1.获取锁屏播放中心
        let playCenter = MPNowPlayingInfoCenter.default()
        
        // 1.0 当前正在播放的歌曲信息
        // 获取当前播放歌曲的所有歌词信息
//        let lrcMs = HTZLrcDataTool.getLrcData(fileName: musicMessageModel.musicModel!.fileName!)
        let lrcMs = HTZLrcDataTool.getLrcModel(lrcContent: musicMessageModel.musicModel!.originalLyricLink!)
        // 获取当前播放的歌词模型
        var lrcM: HTZLrcModel?
        var currentLrcRow = 0
        
        HTZLrcDataTool.getRow(currentTime: musicMessageModel.costTime!, lrcMs: lrcMs) { (row, lrcModel) in
            currentLrcRow = row
            lrcM = lrcModel
        }
        
        // 1.1 字典信息
        let songName = musicMessageModel.musicModel?.song_name
        let singerName = musicMessageModel.musicModel?.singer
        let costTime = musicMessageModel.costTime
        let totalTime = musicMessageModel.totalTime
        let icon = musicMessageModel.musicModel?.icon
        if let icon = icon {
            let image = UIImage(named: icon)
            if let image = image {
                // 如果当前歌词没有播放完毕, 则无需重新绘制新图
                if lrcRow != currentLrcRow {
                    // 重新绘制图片
                    let newImage = UIImage.getNewImage(sourceImage: image, lrcStr: lrcM!.lrcStr!)
                    artwork = MPMediaItemArtwork(boundsSize: newImage.size, requestHandler: { (size) -> UIImage in
                        return newImage
                    })
                    
                    lrcRow = currentLrcRow
                }
                
            }
        }
        
        // 1.2 创建字典
        var infoDict:[String : Any] = [
            MPMediaItemPropertyAlbumTitle : songName!,
        MPMediaItemPropertyArtist : singerName!,
        MPNowPlayingInfoPropertyElapsedPlaybackTime : costTime!,
        MPMediaItemPropertyPlaybackDuration : totalTime!]
        
        if let artwork = artwork {
            infoDict[MPMediaItemPropertyArtwork] = artwork
        }
        
        // 2.给锁屏中心赋值
        playCenter.nowPlayingInfo = infoDict
        
        // 3.接收远程事件
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
}
