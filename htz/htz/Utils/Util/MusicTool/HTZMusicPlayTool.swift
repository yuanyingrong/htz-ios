//
//  HTZMusicPlayTool.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/3.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import AVFoundation

let kPlayFinishNotificationName = "kPlayFinishNotificationName"

class HTZMusicPlayTool: NSObject {
    
    var player: AVAudioPlayer?
    
    
    override init() {
        // 1.获取音频会话
        let session = AVAudioSession.sharedInstance()
        do {
            // 2.设置音频会话类别
            try session.setCategory(AVAudioSession.Category.playback)
        } catch {
            print(error)
//            return nil
        }
        
        do {
            // 3.激活会话
            try session.setActive(true, options: [])
        } catch {
            print(error)
//            return nil
        }
        
    }
    
    /// 播放指定文件的音乐
    ///
    /// - Parameter musicName: 音乐文件名
    /// - Returns: 
    func playMusic(musicName: String) -> Bool {
         // 判断路径是否正确
//        let url = Bundle.main.url(forResource: musicName, withExtension: nil)
        let url = URL(string: "http://htzshanghai.top/resources/audios/xingfuneixinchan/\(musicName)")
        if url == nil {
            return false
        }
        // 判断是否播放同一首歌曲
        if let player = self.player, player.url == url {
            if let player = self.player, !player.isPlaying {
                // 为了暂停后, 能够再播放
                player.play()
            }
            return false
        }
        
        do {
            // 1.创建 player
            try self.player = AVAudioPlayer(contentsOf: url!)
            self.player?.delegate = self
        } catch {
            print(error)
            return false
        }
        
        // 2.准备播放
        self.player?.prepareToPlay()
        
        // 3.开始播放
        self.player?.play()
        
        return true
    }
    
    /// 暂停当前音乐
    func pauseCurrentMusic() {
        self.player?.pause()
    }
    
    /// 继续播放当前音乐
    func resumeCurrentMusic() {
        self.player?.play()
    }
    
    /// 停止当前音乐
    func stopCurrentMusic() {
        if let player = self.player {
            player.stop()
            player.delegate = nil
            self.player = nil
        }
    }
    
    
    /// 指定播放进度
    ///
    /// - Parameter timeInteval: 时间, 指定歌曲已经播放了多长时间
    func seekTo(timeInteval: TimeInterval) {
        self.player?.currentTime = timeInteval
    }

}

// MARK: AVAudioPlayerDelegate
extension HTZMusicPlayTool: AVAudioPlayerDelegate {
    
    /// 监听播放完成
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("歌曲播放完毕")
        // 发布通知
        NotificationCenter.default.post(name: NSNotification.Name.init(kPlayFinishNotificationName), object: nil)
    }
}
