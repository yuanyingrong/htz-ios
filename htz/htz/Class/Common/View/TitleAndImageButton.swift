//
//  TitleAndImageButton.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/7.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class TitleAndImageButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
        setUpUI()
    }
    
    
    func setUpUI() {
        setImage(UIImage(named: "more"), for: .normal)
        setImage(UIImage(named: "more"), for: .selected)
        adjustsImageWhenHighlighted = false
        sizeToFit()
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.frame.origin.x = 0
        imageView?.frame.origin.x = titleLabel!.frame.width
    }
}
