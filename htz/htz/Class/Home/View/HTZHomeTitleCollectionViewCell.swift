//
//  HTZHomeTitleCollectionViewCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/8.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeTitleCollectionViewCell: UICollectionViewCell {
    
    var imageName: String? {
        didSet {
            if imageName!.hasPrefix("http") {
                imageView.wb_setImageWith(urlStr: imageName!)
            } else {
                imageView.image = UIImage(named: imageName ?? "")
            }
        }
    }
    
    var title: String? {
        didSet {
            label.text = title!
        }
    }
    
    private let imageView = UIImageView()
    private let label = UILabel(text: "", font: 16, textColor: .darkText)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configSubViews()
        configConstraint()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configSubViews()
        configConstraint()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
     func configSubViews() {
        
        backgroundColor = .white
        addSubview(imageView)
        addSubview(label)
        
    }
    
     func configConstraint() {
        
        
        imageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.contentView)
        }
        
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalTo(self.contentView)
            make.height.equalTo(24)
            make.bottom.equalTo(self.contentView).offset(-8)
        }
    }
}
