//
//  HTZAlbumViewModel.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/11.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZAlbumViewModel: NSObject {

    var homeTitleModel: HTZHomeTitleModel?
    var dataArr = [HTZSutraInfoModel?]()
//    var dataArr: [HTZHomeImageTitle] {
////        HTZHomeImageTitle(title: "大學", imageName: ""), , HTZHomeImageTitle(title: "孔子家語", imageName: ""), HTZHomeImageTitle(title: "論語", imageName: "")
//        let dataArr = [HTZHomeImageTitle(title: "中庸", imageName: "zhong_yong"), HTZHomeImageTitle(title: "孟子", imageName: "meng_zi"), HTZHomeImageTitle(title: "尚書", imageName: "shang_shu"), HTZHomeImageTitle(title: "傳習錄", imageName: "chuan_xi_lu"), HTZHomeImageTitle(title: "道德經", imageName: "dao_de_jing"), HTZHomeImageTitle(title: "禮記", imageName: "li_ji"), HTZHomeImageTitle(title: "六祖壇經", imageName: "liu_zu_tan_jing"), HTZHomeImageTitle(title: "五常", imageName: "wu_chang"), HTZHomeImageTitle(title: "忠經", imageName: "zhong_jing"), HTZHomeImageTitle(title: "朱子晚年定論", imageName: "zhu_zi_wan_nian_ding_lun")]
//
//
//        return dataArr
//    }
    
    func requestData(page_index: Int, callBack: @escaping (Bool, _ code:String) -> ()) {
        NetWorkRequest(API.sutras(page_index: page_index, page_size: 20)) { (response) -> (Void) in
            
            if response["code"].rawString() == "200" {
                let arr = [HTZSutraInfoModel].deserialize(from: response["data"].rawString())
                if let arr = arr {
                    for sutra in arr {
                        sutra?.cover = "\(ossurl)/\(sutra?.cover ?? "")"
                    }
                    self.dataArr = arr
                    
                    callBack(true, "200")
                }
            } else if response["code"].rawString() == "20100" {
                // token invalid 重新登录
                callBack(false, "20100")
            }
            
        }
    }
}
