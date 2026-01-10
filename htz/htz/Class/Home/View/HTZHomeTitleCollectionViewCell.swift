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
    
    // Frame layout setup flag
    private var didSetupFrameLayout = false
    
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
        setupForFrameLayoutOnce()
        //        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupForFrameLayoutOnce() {
        guard !didSetupFrameLayout else { return }
        didSetupFrameLayout = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = true
        label.translatesAutoresizingMaskIntoConstraints = true
        
        // 精准清理残留约束：只移除与 imageView 或 label 相关的约束
        self.constraints.forEach { constraint in
            if constraint.firstItem as? UIView == imageView || 
               constraint.secondItem as? UIView == imageView ||
               constraint.firstItem as? UIView == label || 
               constraint.secondItem as? UIView == label {
                constraint.isActive = false
            }
        }
        contentView.constraints.forEach { constraint in
            if constraint.firstItem as? UIView == imageView || 
               constraint.secondItem as? UIView == imageView ||
               constraint.firstItem as? UIView == label || 
               constraint.secondItem as? UIView == label {
                constraint.isActive = false
            }
        }
    }
    
    func configSubViews() {
        setupForFrameLayoutOnce()
        
        backgroundColor = .white
        contentView.backgroundColor = .white
        
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 只 reset UI，不触发 didSet
        imageView.image = nil
        label.text = nil
    }
    
     func configConstraint() {
        // 已移除 SnapKit 约束，改用纯 frame 布局
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 手动设置 ImageView 的 frame
        let imageViewSize = contentView.bounds.width
        imageView.frame = CGRect(x: 0, y: 0, width: imageViewSize, height: imageViewSize)

        // 设置 label 的位置
        let labelSpacing: CGFloat = 5
        let labelHeight: CGFloat = 20
        let labelY = imageView.frame.maxY + labelSpacing
        label.frame = CGRect(x: 0, y: labelY, width: imageViewSize, height: labelHeight)
    }
}