//
//  HTZMusicLyricView.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZMusicLyricView: BaseView {

    /// 歌词信息
    var lyrics: [String]?
    var lyricIndex: NSInteger?
    
    /// 是否将要拖拽歌词
    var isWillDraging: Bool?
    
    /// 是否正在滚动歌词
    var isScrolling: Bool?
    /// 声音视图滑动开始或结束block
    var volumeViewSliderBlock: ((_ isBegan: Bool) -> (Void))?

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LyricCell")
        return tableView
    }()
    
    /// 滑动歌词的方法
    ///
    /// - Parameters:
    ///   - currentTime: 当前时间
    ///   - totalTime: 总时间
    func scrollLyric(currentTime: TimeInterval, totalTime: TimeInterval) {
        
    }
    
    /// 隐藏系统音量试图
    func hideSystemVolumeView() {
        
    }
    
    /// 显示系统音量试图
    func showSystemVolumeView() {
        
    }
}

extension HTZMusicLyricView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lyrics!.count + 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LyricCell", for: indexPath)
        cell.textLabel?.textColor = UIColor.gray
        cell.textLabel?.textAlignment = NSTextAlignment.center
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.selectedBackgroundView = UIView()
        cell.backgroundColor = UIColor.clear
        if (indexPath.row < 5 || indexPath.row > self.lyrics!.count + 4) {
            cell.textLabel?.textColor = UIColor.clear
            cell.textLabel?.text  = ""
        } else {
//            cell.textLabel?.text = self.lyrics?[indexPath.row - 5].contains
            
            if (indexPath.row == self.lyricIndex! + 5) {
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
            } else {
                cell.textLabel?.textColor = UIColor.gray
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            }
        }
        return cell
    }
    
    
}
