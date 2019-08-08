//
//  BaseView.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configInterface()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configInterface() {
        configSubviews()
        configConstraint()
        configViewData()
    }
    
    func configSubviews() {
        backgroundColor = .white
    }
    
    func configViewData() {
        
    }
    
    func configConstraint() {
        
    }

}
