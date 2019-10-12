//
//  HTZHomeViewModel.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/8.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

struct HTZHomeImageTitle {
    
    var title: String?
    var imageName: String?
    
    
}

class HTZHomeViewModel: NSObject {

    var homeTitleModel: HTZHomeTitleModel?
    var dataArr = [HTZAlbumModel?]()
//    var dataArr: [HTZHomeImageTitle] {
////        HTZHomeImageTitle(title: "大學", imageName: ""), , HTZHomeImageTitle(title: "孔子家語", imageName: ""), HTZHomeImageTitle(title: "論語", imageName: "")
//        let dataArr = [HTZHomeImageTitle(title: "中庸", imageName: "zhong_yong"), HTZHomeImageTitle(title: "孟子", imageName: "meng_zi"), HTZHomeImageTitle(title: "尚書", imageName: "shang_shu"), HTZHomeImageTitle(title: "傳習錄", imageName: "chuan_xi_lu"), HTZHomeImageTitle(title: "道德經", imageName: "dao_de_jing"), HTZHomeImageTitle(title: "禮記", imageName: "li_ji"), HTZHomeImageTitle(title: "六祖壇經", imageName: "liu_zu_tan_jing"), HTZHomeImageTitle(title: "五常", imageName: "wu_chang"), HTZHomeImageTitle(title: "忠經", imageName: "zhong_jing"), HTZHomeImageTitle(title: "朱子晚年定論", imageName: "zhu_zi_wan_nian_ding_lun")]
//
//
//        return dataArr
//    }
    
    func requestData(isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
        NetWorkRequest(API.albums) { (response) -> (Void) in
            
            let arr = [HTZAlbumModel].deserialize(from: response["sutra_items"].rawString())
            if let arr = arr {
                self.dataArr = arr
                
                let model = HTZAlbumModel()
                model.title = "觅心小视频(视频)"
                model.icon = "play_normal"
                model.playcount = "0"
                model.item_total = "11"
                model.desc = "1111111111111111111"
                model.isVideo = true
                self.dataArr.insert(model, at: 0)
                
                callBack(true)
            }
            print(response["sutra_items"])
        }
    }
}
