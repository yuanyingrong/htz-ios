//
//  HTZPersonalProfileShowTableViewCell.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/28.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZPersonalProfileShowTableViewCell: UITableViewCell {
    
    var leftStr: String? {
        didSet {
            if let leftStr = leftStr {
                titleLabel.text = leftStr
            }
        }
    }
    
    var rightStr: String? {
        didSet {
            if let rightStr = rightStr {
                rightLabel.text = rightStr
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
        contentView.addSubview(rightLabel)
        contentView.addSubview(bottomLine)
    }
    
    public func configConstraint() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(0.5 * kGlobelMargin)
            make.left.equalTo(contentView).offset(2 * kGlobelMargin)
            make.bottom.equalTo(contentView).offset(-0.5 * kGlobelMargin)
        }
        
        rightLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.right.equalTo(contentView).offset(-2 * kGlobelMargin)
        }
        
        
        bottomLine.snp.makeConstraints { (make) in
//            make.top.equalTo(titleLabel.snp.bottom).offset(0.5 * kGlobelMargin)
            make.left.bottom.right.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
    
    private let titleLabel = UILabel(title: "--", fontSize: 16, textColor: UIColor.darkText)

    private let rightLabel = UILabel(title: "--", fontSize: 16, textColor: UIColor.darkText)
    
    private lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.groupTableViewBackground
        return bottomLine
    }()
    

}
