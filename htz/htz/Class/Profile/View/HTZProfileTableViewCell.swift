//
//  HTZProfileTableViewCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/26.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZProfileTableViewCell: BaseTableViewCell {
    
    var imageName: String? {
        didSet {
            if imageName!.hasPrefix("http") {
                leftImageView.wb_setImageWith(urlStr: imageName!)
            } else {
                leftImageView.image = UIImage(named: imageName ?? "")
            }
        }
    }
    
    var title: String? {
        didSet {
            label.text = title!
        }
    }
    
    private let leftImageView = UIImageView()
    private let label = UILabel(text: "", font: 24, textColor: .red)
    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView(image: UIImage(named: "enter"))
        return arrowImageView
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
        
        contentView.addSubview(leftImageView)
        contentView.addSubview(label)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(bottomLine)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        leftImageView.snp_makeConstraints { (make) in
            make.left.top.equalTo(contentView).offset(20)
            make.size.equalTo(CGSize(width: 44, height: 44))
            make.bottom.equalTo(contentView).offset(-16)
        }
        
        label.snp_makeConstraints { (make) in
            make.left.equalTo(leftImageView.snp_right).offset(16)
            make.centerY.equalTo(leftImageView)
        }
        
        arrowImageView.snp_makeConstraints { (make) in
            make.right.equalTo(contentView).offset(-16)
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.centerY.equalTo(contentView)
        }
        
        bottomLine.snp_makeConstraints { (make) in
            make.left.bottom.right.equalTo(contentView)
            make.height.equalTo(1)
        }
    }

}
