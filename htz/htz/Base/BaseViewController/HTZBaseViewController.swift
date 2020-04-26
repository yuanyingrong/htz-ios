//
//  BaseViewController.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // Do any additional setup after loading the view.
        self.configInterface()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configInterface(){
        self.configSelf()
        self.configSubView()
        self.configConstraint()
        self.configData()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super .init(coder: aDecoder)
        
        //        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super .init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configInterface()
    }
    
    // 配置自身
    public func configSelf() {}
    // 配置subView
    public func configSubView() {}
    // 配置约束
    public func configConstraint() {}
    // 配置数据
    public func configData () {}

}
