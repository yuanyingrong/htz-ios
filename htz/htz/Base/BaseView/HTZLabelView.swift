//
//  HTZLabelView.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/27.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZLabelView: BaseView {
    
    var title: String? {
        didSet {
            label.text = title!
        }
    }
    
    private let label = UILabel(text: "", font: 16, textColor: .red)

    override func configSubviews() {
        super.configSubviews()
        
        addSubview(label)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        label.snp.makeConstraints { (make) in
            make.center.equalTo(self)
        }
    }

}
