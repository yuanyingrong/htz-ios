//
//  BaseViewModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class BaseViewModel: NSObject {

    var title : String?
    var params: [String:Any]?
    
    override init() {
        super.init()
    }
    
    func initWithViewModel(_ model:BaseModel?,_ params:[String:Any]?) {
        title = params!["title"] as? String
    }
}
