//
//  HTZToDownloadListCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/18.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit


protocol HTZToDownloadListCellDelegate: NSObjectProtocol {
    
    func deleteAction(_ cell: HTZToDownloadListCell);
}

class HTZToDownloadListCell: BaseTableViewCell {
    
    var downloadModel: HTZDownloadModel? {
        
        didSet {
            if let downloadModel = downloadModel {
                titleLabel.text = downloadModel.fileName
                //                if albumPartModel.icon!.hasPrefix("http") {
                //                    albumImageView.wb_setImageWith(urlStr: albumPartModel.icon!)
                //                } else {
                //                    albumImageView.image = UIImage(named: albumModel.icon ?? "")
                //                }
                playCountButton.setTitle(String(format: "%@/%@", downloadModel.fileCurrentSize ?? "", downloadModel.fileSize ?? ""), for: UIControl.State.normal)
                playTimeLabel.text = ""
//                downloadModel.state
            }
        }
    }
    
    var musicModel: HTZMusicModel? {
        
        didSet {
            if let musicModel = musicModel {
                titleLabel.text = musicModel.song_name
                //                if albumPartModel.icon!.hasPrefix("http") {
                //                    albumImageView.wb_setImageWith(urlStr: albumPartModel.icon!)
                //                } else {
                //                    albumImageView.image = UIImage(named: albumModel.icon ?? "")
                //                }
                playCountButton.setTitle(musicModel.lrcName, for: UIControl.State.normal)
                playTimeLabel.text = ""
            }
        }
    }
    
    var imageName: String? {
        didSet {
            if imageName!.hasPrefix("http") {
                albumImageView.wb_setImageWith(urlStr: imageName!)
            } else {
                albumImageView.image = UIImage(named: imageName ?? "")
            }
        }
    }
    
    weak var delegate: HTZToDownloadListCellDelegate?
    
    
    private lazy var albumImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "li_ji")
        imageView.cornerRadius = 22
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let titleLabel = UILabel(title: "1、第一讲", fontSize: 16, textColor: UIColor.darkText)
    
    private lazy var playCountButton: UIButton = {
        let playCountButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        playCountButton.set(image: UIImage(named: "play_count"), title: "555", titlePosition: UIView.ContentMode.right , additionalSpacing: 8, state: UIControl.State.normal)
        playCountButton.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        return playCountButton
    }()
    
    private lazy var timeButton: UIButton = {
        let timeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        timeButton.set(image: UIImage(named: "time"), title: "21:47", titlePosition: UIView.ContentMode.right , additionalSpacing: 4, state: UIControl.State.normal)
        timeButton.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        return timeButton
    }()
    
    private let playTimeLabel = UILabel(title: "已播60%", fontSize: 13, textColor: UIColor.red)
    
    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton(type: UIButton.ButtonType.custom)
        deleteButton.setImage(UIImage(named: "delete"), for: UIControl.State.normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonClickAction), for: UIControl.Event.touchUpInside)
        return deleteButton
    }()
    
    private lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.groupTableViewBackground
        return bottomLine
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func configSubView() {
        super.configSubView()
        
        contentView.addSubview(albumImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(playCountButton)
        contentView.addSubview(timeButton)
        contentView.addSubview(playTimeLabel)
        contentView.addSubview(deleteButton)
        contentView.addSubview(bottomLine)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        albumImageView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(0.5 * kGlobelMargin)
            make.left.equalTo(contentView).offset(kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(albumImageView)
            make.left.equalTo(albumImageView.snp.right).offset(2 * kGlobelMargin)
        }
        
        playCountButton.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            //            make.size.equalTo(CGSize(width: 60, height: 28))
            make.bottom.equalTo(albumImageView)
        }
        
        timeButton.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(playCountButton)
            make.left.equalTo(playCountButton.snp.right).offset(3 * kGlobelMargin)
        }
        
        playTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(timeButton)
            make.left.equalTo(timeButton.snp.right).offset(3 * kGlobelMargin)
        }
        
        deleteButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentView)
            make.right.equalTo(contentView).offset((-3 * kGlobelMargin))
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(albumImageView.snp.bottom).offset(0.5 * kGlobelMargin)
            make.left.bottom.right.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
    
}

extension HTZToDownloadListCell {
    
    @objc private func deleteButtonClickAction() {
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("deleteAction:"))) {
            delegate.deleteAction(self)
        }
    }
}

