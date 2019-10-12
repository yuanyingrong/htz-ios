//
//  HTZVideoPlaySJViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/12.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import NicooPlayer

class HTZVideoPlaySJViewController: UIViewController {
    
    var videoUrl: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        
        view.addSubview(fatherView)
        // Do any additional setup after loading the view.
        let url = URL(string: videoUrl ?? "")
        videoPlayer.playVideo(url, nil, fatherView)
    }
    

    private func _setupViews() {
        
    }
    
    fileprivate lazy var videoPlayer: NicooPlayerView = {
           let player = NicooPlayerView(frame: self.view.frame, bothSidesTimelable: true)
           player.delegate = self
           return player
    }()
    
    lazy var fatherView: UIView = {
        let view = UIView()
        view.frame = CGRect(x:0, y: 100, width: kScreenWidth, height: kScreenWidth*9/16)
        view.backgroundColor = UIColor.gray
        return view
    }()

}

/// MARK: - NicooPlayerDelegate
extension HTZVideoPlaySJViewController: NicooPlayerDelegate {
    
    func retryToPlayVideo(_ player: NicooPlayerView, _ videoModel: NicooVideoModel?, _ fatherView: UIView?) {
        
    }
    
    
    
    
}
