//
//  HTZAlbumListViewModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZAlbumListViewModel: NSObject {
    
    var dataArr = [HTZAlbumPartModel?]()
    
    func requestData(isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
        NetWorkRequest(API.xingfuneixinchan) { (response) -> (Void) in
            
            let arr = [HTZAlbumPartModel].deserialize(from: response["sutra_items"].rawString())
            if let arr = arr {
                self.dataArr = arr
                callBack(true)
            }
            print(response["sutra_items"])
        }
    }

}
