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
    var dataArr = [HTZSutraInfoModel?]()
//    var dataArr: [HTZHomeImageTitle] {
////        HTZHomeImageTitle(title: "大學", imageName: ""), , HTZHomeImageTitle(title: "孔子家語", imageName: ""), HTZHomeImageTitle(title: "論語", imageName: "")
//        let dataArr = [HTZHomeImageTitle(title: "中庸", imageName: "zhong_yong"), HTZHomeImageTitle(title: "孟子", imageName: "meng_zi"), HTZHomeImageTitle(title: "尚書", imageName: "shang_shu"), HTZHomeImageTitle(title: "傳習錄", imageName: "chuan_xi_lu"), HTZHomeImageTitle(title: "道德經", imageName: "dao_de_jing"), HTZHomeImageTitle(title: "禮記", imageName: "li_ji"), HTZHomeImageTitle(title: "六祖壇經", imageName: "liu_zu_tan_jing"), HTZHomeImageTitle(title: "五常", imageName: "wu_chang"), HTZHomeImageTitle(title: "忠經", imageName: "zhong_jing"), HTZHomeImageTitle(title: "朱子晚年定論", imageName: "zhu_zi_wan_nian_ding_lun")]
//
//
//        return dataArr
//    }
    
    func requestData(callBack: @escaping (Bool, _ code:String) -> ())  {
        NetWorkRequest(API.albums) { [weak self] (response) -> (Void) in

            print("🔐 [LOGIN] requestData response: \(response)")
            print("🔐 [LOGIN] response[\"code\"]: \(response["code"].rawString())")
            print("🔐 [LOGIN] response[\"data\"]: \(response["data"])")

            let arr = [HTZSutraInfoModel].deserialize(from: response["data"].rawString())
            print("🔐 [LOGIN] deserialized arr: \(arr)")
            print("🔐 [LOGIN] arr count: \(arr?.count ?? 0)")

            if let arr = arr {
                // 拼接 OSS URL，与专辑 Tab 保持一致
                for sutra in arr {
                    sutra?.cover = "\(ossurl)\(sutra?.cover ?? "")"
                }
                self?.dataArr = arr

                let model = HTZSutraInfoModel()
                model.name = "觅心小视频(视频)"
                model.cover = "play_normal"
                model.played_count = 0
                model.item_total = 11
                model.desc = "1111111111111111111"
                model.isVideo = true
                self?.dataArr.insert(model, at: 0)

                print("🔐 [LOGIN] Calling callBack with code: 200")
                callBack(true, "200")
            } else if response["code"].rawString() == "20100" {
                // token invalid 重新登录
                print("🔐 [LOGIN] Token invalid, calling callBack with code: 20100")
                callBack(false, "20100")
            } else {
                print("🔐 [LOGIN] Data parsing failed and code is not 20100, no callback will be called!")
            }

        }
    }
    
    func requestData(isPullDown: Bool, callBack: @escaping (Bool) -> ()) {
        // recommendations
        NetWorkRequest(API.albums) { (response) -> (Void) in

            let arr = [HTZSutraInfoModel].deserialize(from: response["data"].rawString())
            if let arr = arr {
                // 拼接 OSS URL，与专辑 Tab 保持一致
                for sutra in arr {
                    sutra?.cover = "\(ossurl)\(sutra?.cover ?? "")"
                }
                self.dataArr = arr

                let model = HTZSutraInfoModel()
                model.name = "觅心小视频(视频)"
                model.cover = "play_normal"
                model.played_count = 0
                model.item_total = 11
                model.desc = "1111111111111111111"
                model.isVideo = true
                self.dataArr.insert(model, at: 0)

                callBack(true)
            }
            print(response["data"])
        }
    }
}
