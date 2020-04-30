//
//  HTZPersonalProfilePortraitCell.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/28.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZPersonalProfilePortraitCell: UITableViewCell {
    
    var leftStr: String? {
        didSet {
            if let leftStr = leftStr {
                titleLabel.text = leftStr
            }
        }
    }
    
    var portraitImage: String? {
        didSet {
            if let portraitImage = portraitImage, portraitImage.length > 0 {
                portraitImageView.wb_setImageWith(urlStr: portraitImage, placeHolder: "头像")
            }
        }
    }
    
    
    

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
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(portraitImageView)
        contentView.addSubview(bottomLine)
    }
    
    public func configConstraint() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(0.5 * kGlobelMargin)
            make.left.equalTo(contentView).offset(2 * kGlobelMargin)
            make.bottom.equalTo(contentView).offset(-0.5 * kGlobelMargin)
        }
        
        portraitImageView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(titleLabel)
            make.right.equalTo(contentView).offset(-2 * kGlobelMargin)
            make.width.equalTo(portraitImageView.snp.height)
        }
        
        
        bottomLine.snp.makeConstraints { (make) in
//            make.top.equalTo(titleLabel.snp.bottom).offset(0.5 * kGlobelMargin)
            make.left.bottom.right.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
    
    private lazy var portraitImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "头像")
        return imageView
    }()
    
    private let titleLabel = UILabel(title: "--", fontSize: 16, textColor: UIColor.darkText)

    
    private lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.groupTableViewBackground
        return bottomLine
    }()
    

}
