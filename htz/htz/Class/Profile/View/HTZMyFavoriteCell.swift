//
//  HTZMyFavoriteCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/20.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZMyFavoriteCellDelegate: NSObjectProtocol {
    
    func deleteAction(_ cell: HTZMyFavoriteCell);
}

class HTZMyFavoriteCell: UITableViewCell {
    
    var saveDataModel: HTZSaveDataModel? {
        
        didSet {
            if let saveDataModel = saveDataModel {
                titleLabel.text = saveDataModel.albumTitle
                if let albumIcon = saveDataModel.albumIcon, albumIcon.hasPrefix("http") {
                    albumImageView.wb_setImageWith(urlStr: albumIcon)
                } else {
                    albumImageView.image = UIImage(named: saveDataModel.albumIcon ?? "")
                }
                fileCountButton.setTitle("saveDataModel.fileCount!集", for: UIControl.State.normal)
            }
        }
    }
    
    weak var delegate: HTZMyFavoriteCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configSubView()
        configConstraint()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configSubView()
        configConstraint()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    public func configSubView() {
        contentView.addSubview(albumImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(fileCountButton)
        contentView.addSubview(deleteButton)
        contentView.addSubview(bottomLine)
    }
    
    public func configConstraint() {
        albumImageView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(0.5 * kGlobelMargin)
            make.left.equalTo(contentView).offset(kGlobelMargin)
            make.size.equalTo(CGSize(width: 66, height: 66))
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(albumImageView)
            make.left.equalTo(albumImageView.snp.right).offset(2 * kGlobelMargin)
        }
        
        fileCountButton.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            //            make.size.equalTo(CGSize(width: 60, height: 28))
            make.bottom.equalTo(albumImageView)
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
    
    private lazy var albumImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "li_ji")
        imageView.cornerRadius = 22
        return imageView
    }()
    
    private let titleLabel = UILabel(title: "幸福内心禅", fontSize: 16, textColor: UIColor.darkText)
    
    private lazy var fileCountButton: UIButton = {
        let fileCountButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        fileCountButton.set(image: UIImage(named: "play_count"), title: "555M", titlePosition: UIView.ContentMode.right , additionalSpacing: 8, state: UIControl.State.normal)
        fileCountButton.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        return fileCountButton
    }()

    
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
    
    
}

extension HTZMyFavoriteCell {
    
    @objc private func deleteButtonClickAction() {
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("deleteAction:"))) {
            delegate.deleteAction(self)
        }
        
    }
}
