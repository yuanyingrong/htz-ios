//
//  HTZAIViewController.swift
//  htz
//
//  Created by Gemini on 2025/12/16.
//

import UIKit

class HTZAIViewController: HTZBaseViewController {

    override var pageTraceName: String? {
        return "AI"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AI"
        
        let label = UILabel()
        label.text = "功能开发中..."
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalTo(view)
        }
    }
}
