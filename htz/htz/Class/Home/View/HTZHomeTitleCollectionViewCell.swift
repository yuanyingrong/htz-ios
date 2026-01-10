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
            if let imageName = imageName,imageName.hasPrefix("http") {
                imageView.wb_setImageWith(urlStr: imageName)
            } else {
                if let imageName = imageName, !imageName.isEmpty {
                    imageView.image = UIImage(named: imageName)
                } else {
                    imageView.image = UIImage(named: "htz_no_title")
                }
            }
//            if let imageName = imageName, imageName.starts(with: "tests") {
//                imageView.htz_setImage(fileId: imageName)
//            }
        }
    }
    
    var title: String? {
        didSet {
            if let title = title {
                label.text = title
            }
            
        }
    }
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.layer.masksToBounds = true
        return iv
    }()

    private let label = UILabel(text: "", font: 13, textColor: .darkText)
    
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
        // 只设置 label 的约束
        label.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.contentView)
            make.height.equalTo(20)
            make.bottom.equalTo(self.contentView).offset(-5)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 手动设置 ImageView 的 frame
        let imageViewHeight = contentView.bounds.width  // 正方形，高度等于宽度
        imageView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: imageViewHeight)

        // 设置 label 的位置
        label.frame = CGRect(x: 0, y: imageViewHeight + 5, width: contentView.bounds.width, height: 20)
    }
}
