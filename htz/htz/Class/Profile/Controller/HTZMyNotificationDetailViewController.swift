//
//  HTZMyNotificationDetailViewController.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/26.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZMyNotificationDetailViewController: HTZBaseScrollViewController {
    
    var content: String? {
        didSet {
            contentLabel.text = content
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func configSubView() {
        super.configSubView()
        
        contentView.addSubview(contentLabel)
    }
    
    override func configConstraint() {
        super.configConstraint()
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.topMargin).offset(2 * kGlobelMargin)
            make.left.equalTo(contentView).offset(2 * kGlobelMargin)
            make.right.equalTo(contentView).offset(-2 * kGlobelMargin)
            make.bottom.equalTo(contentView)
        }
    }
    

   private let contentLabel = UILabel(text: "", font: 24, textColor: .black)
}
