//
//  HTZPlayViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/13.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import AVFoundation

class HTZPlayViewController: BaseViewController {

    private lazy var playButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "stop"), for: UIControl.State.selected)
        button.addTarget(self, action: #selector(playOrPauseMusic), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var previousButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "pre"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(previousMusic), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "next"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(nextMusic), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //   接收打断的通知
        NotificationCenter.default.addObserver(self, selector: #selector(nextMusic), name: NSNotification.Name(rawValue: kPlayFinishNotificationName), object: nil)
        
        //   接收打断的通知
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruptionNotification(noti:)), name: AVAudioSession.interruptionNotification, object: nil)

    }
    
    override func configSubView() {
        super.configSubView()
        
        view.addSubview(playButton)
        view.addSubview(previousButton)
        view.addSubview(nextButton)
        
    }

    
    override func configConstraint() {
        super.configConstraint()
        
        playButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(2 * kGlobelMargin)
            } else {
                make.bottom.equalTo(view).offset(2 * kGlobelMargin)
            }
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        previousButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.right.equalTo(playButton.snp_left).offset(-4 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        nextButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.left.equalTo(playButton.snp_right).offset(4 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
    }
    
    
    deinit {
        // 移除监听
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension HTZPlayViewController {
    
    //
    @objc private func audioSessionInterruptionNotification(noti: Notification) {
     
        print(noti.userInfo)
        
        // 获取类型
        let type = noti.userInfo?[AVAudioSessionInterruptionTypeKey] as! AVAudioSession.InterruptionType
        if type == AVAudioSession.InterruptionType.began {
            // 暂停音乐
            self.playButton.isSelected = true
            playOrPauseMusic()
        } else if type == AVAudioSession.InterruptionType.ended {
            // 播放音乐
            self.playButton.isSelected = false
            playOrPauseMusic()
            // 暂停音乐
            self.playButton.isSelected = true
            playOrPauseMusic()
            // 播放音乐
            self.playButton.isSelected = false
            playOrPauseMusic()
        }
    }
    
}

// MARK: - 按钮点击事件
extension HTZPlayViewController {
    
    // 播放或暂停按钮点击事件
    @objc private func playOrPauseMusic() {
        self.playButton.isSelected = !playButton.isSelected
        if self.playButton.isSelected {
            HTZMusicOperationTool.sharedInstance.playCurrentMusic()
        } else {
            HTZMusicOperationTool.sharedInstance.pauseCurrentMusic()
        }
    }
    
    // 上一曲按钮点击事件
    @objc private func previousMusic() {
        if HTZMusicOperationTool.sharedInstance.preMusic() {
            
        }
    }
    
    // 下一曲按钮点击事件
    @objc private func nextMusic() {
        if HTZMusicOperationTool.sharedInstance.nextMusic() {
            
        }
    }
    
}
