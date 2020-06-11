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
    var lyrics: [HTZLyricModel]? {
        didSet {
            if let lyrics = lyrics {
                if lyrics.count > 0 {
                    self.tipsLabel.isHidden = true
                    self.tableView.reloadData()
                    // 滚动到中间行
                    let indexPath = IndexPath(row: 4, section: 0)
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                } else {
                    self.tipsLabel.isHidden = false
                    self.tipsLabel.text = "暂无歌词"
                    self.tableView.reloadData()
                }
            } else {
                self.tipsLabel.isHidden = false
//                self.tipsLabel.text = "歌词加载中..."
                self.tipsLabel.text = "暂无歌词"
                self.tableView.reloadData()
            }
            
        }
    }
    var lyricIndex: NSInteger = 0
    
    /// 是否将要拖拽歌词
    var isWillDraging: Bool = false
    
    /// 是否正在滚动歌词
    var isScrolling: Bool = false
    /// 声音视图滑动开始或结束block
    var volumeViewSliderBlock: ((_ isBegan: Bool) -> (Void))?

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.backgroundColor = UIColor.clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LyricCell")
        return tableView
    }()
    
    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 17.0)
        label.isHidden = true
        return label
    }()
    
    private lazy var timeLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.isHidden = true
        return view
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.isHidden = true
        return label
    }()
    
    override func configSubviews() {
        super.configSubviews()
        self.backgroundColor = UIColor.groupTableViewBackground
        
        self.addSubview(tableView)
        self.addSubview(tipsLabel)
        self.addSubview(timeLineView)
        self.addSubview(timeLabel)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(kGlobelMargin)
            make.left.right.bottom.equalTo(self)
        }
        
        self.tipsLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.tableView)
        }
        
        self.timeLineView.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(50)
            make.right.equalTo(self).offset(-50)
            make.center.equalTo(self.tableView)
            make.height.equalTo(0.5)
        }
        
        self.timeLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.timeLineView.snp.right).offset(3 * kGlobelMargin)
            make.centerY.equalTo(self.timeLineView.snp.centerY)
        }
    }
    
    /// 滑动歌词的方法
    ///
    /// - Parameters:
    ///   - currentTime: 当前时间
    ///   - totalTime: 总时间
    func scrollLyric(currentTime: TimeInterval, totalTime: TimeInterval) {
        if let lyrics = self.lyrics, lyrics.count != 0 {
            for (idx, currenLyric) in lyrics.enumerated() {
                var nextLyric: HTZLyricModel?
                if idx < lyrics.count - 1 {
                    nextLyric = lyrics[idx + 1]
                }
                
                if (self.lyricIndex != idx && currentTime > currenLyric.msTime!) && (nextLyric == nil || currentTime < (nextLyric?.msTime!)!) {
                    self.lyricIndex = idx
                    
                    self.tableView.reloadData()
                    
                    // 不是由拖拽产生的滚动，自动滚滚动歌词
                    if !self.isScrolling {
                        let indexPath = IndexPath(row: self.lyricIndex + 5, section: 0)
                        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                    }
                }
                
            }
            
        } else {
            self.lyricIndex = 0
        }
        
        
    }
    
    /// 隐藏系统音量试图
    func hideSystemVolumeView() {
        
    }
    
    /// 显示系统音量试图
    func showSystemVolumeView() {
        
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMusicLyricView: UITableViewDataSource, UITableViewDelegate {
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         // 多加10行，是为了上下留白
        if let lyrics = self.lyrics {
            return lyrics.count + 10
        }
        return 10
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LyricCell", for: indexPath)
        cell.textLabel?.textColor = UIColor.gray
        cell.textLabel?.textAlignment = NSTextAlignment.center
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.selectedBackgroundView = UIView()
        cell.backgroundColor = UIColor.clear
        
        cell.textLabel?.text  = ""
        guard let lyrics = self.lyrics else { return cell }
        if (indexPath.row < 5 || indexPath.row > lyrics.count + 4) {
            cell.textLabel?.textColor = UIColor.clear
            cell.textLabel?.text  = ""
        } else {
            cell.textLabel?.text = lyrics[indexPath.row - 5].content
            
            if (indexPath.row == self.lyricIndex + 5) {
                cell.textLabel?.textColor = UIColor.red
                cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
            } else {
                cell.textLabel?.textColor = UIColor.gray
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            }
        }
        return cell
    }
}


// MARK: - UIScrollViewDelegate
extension HTZMusicLyricView: UIScrollViewDelegate {
    
    /// 将要开始拖拽
    internal func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isWillDraging = true
        // 取消前面的延时操作
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.isScrolling = true
        
        // 显示分割线和时间
        self.timeLineView.isHidden = false
        self.timeLabel.isHidden = false
    }
    
    // 拖拽结束，是否需要减速
    internal func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.isWillDraging = false
            self.perform(Selector(("endedScroll")), with: nil, afterDelay: 1)
        }
    }
    
    // 将要开始减速，上面的decelerate为yes时触发
    internal func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.isScrolling = true
    }
    
    // 减速停止
    internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isWillDraging = false
        self.perform(Selector(("endedScroll")), with: nil, afterDelay: 1)
    }
    
    // scrollView滑动时
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !self.isScrolling { return } // 不是由拖拽产生的滚动
        
        // 获取滚动距离
        let offsetY = scrollView.contentOffset.y
        
        // 根据跟单距离计算行数（滚动距离 + tableview高度的一半）/ 行高 + 5 - 1
        
        let index = (offsetY + self.tableView.frame.size.height * 0.5) / 44 + 5 - 1
        
        // 根据对应的索引取出歌词模型
        var model: HTZLyricModel?
        
        if index < 0 {
            model = self.lyrics?.first
        } else if index > CGFloat(self.lyrics?.count ?? 0) - 1 {
            model = nil
        } else {
            model = self.lyrics?[NSInteger(index)]
        }
        // 设置对应的时间
        if let model = model {
            self.timeLabel.text = HTZMusicTool.timeStr(secTime: model.secTime!)
            self.timeLabel.isHidden = false
        } else {
            self.timeLabel.text = ""
            self.timeLabel.isHidden = true
        }
    }
    
    @objc private func endedScroll() {
        if self.isWillDraging { return }
        self.timeLineView.isHidden = true
        self.timeLabel.isHidden = true
        
        // 4秒后继续滚动歌词
        self.perform(Selector(("endScrolling")), with: nil, afterDelay: 4)
    }
    
    @objc private func endScrolling() {
        if self.isWillDraging { return }
        self.isScrolling = false
    }
}
