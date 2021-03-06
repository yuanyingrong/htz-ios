//
//  HTZLoginManager.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/26.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZLoginManager: NSObject {
    
    static let shared = HTZLoginManager()
    
    func jumpToWechatLogin(controller: UIViewController) {
        
        let vc = HTZWechatLoginViewController()
        controller.navigationController?.pushViewController(vc, animated: true)
        vc.loginResult = { loginModel in
            let dict:[String : Any?] = [
                "token":loginModel?.token,
                "name":loginModel?.name,
                "id":loginModel?.id,
                "union_id":loginModel?.union_id,
                "mobile":loginModel?.mobile,
                "gender":loginModel?.gender,
                "created_at":loginModel?.created_at,
                "avatar":loginModel?.avatar,
                "birthday_year":loginModel?.birthday_year,
                "country":loginModel?.wx_login_resp?.country,
                "unionid":loginModel?.wx_login_resp?.unionid,
                "city":loginModel?.wx_login_resp?.city,
                "province":loginModel?.wx_login_resp?.province,
                "privilege":loginModel?.wx_login_resp?.privilege,
                "sex":loginModel?.wx_login_resp?.sex,
                "nickname":loginModel?.wx_login_resp?.nickname,
                "openid":loginModel?.wx_login_resp?.openid,
                "headimgurl":loginModel?.wx_login_resp?.headimgurl]
            
            
            
            
            
            let param:[String : Any?] = [
                                          "city": loginModel?.wx_login_resp?.city,
                                          "country": loginModel?.wx_login_resp?.country,
                                          "createTime": Date.getTime(timeStamp: loginModel?.created_at ?? "", format: .dateYMDHMS),
                                          "groupId": 0,
                                          "headimgurl": loginModel?.wx_login_resp?.headimgurl,
//                                          "id": loginModel?.id,
                                          "language": "",
                                          "lastUpdateTime": "",
                                          "nickname": loginModel?.wx_login_resp?.nickname,
                                          "note": "",
                                          "openid": loginModel?.wx_login_resp?.openid,
                                          "province": loginModel?.wx_login_resp?.province,
                                          "pwd": "",
                                          "sex": loginModel?.wx_login_resp?.sex,
                                          "sign": "",
                                          "telephone": "",
                                          "unionid": loginModel?.wx_login_resp?.unionid
                                        ]
            
            NetWorkRequest(API.addUserInfo(parameters: param as [String : Any])) { (response) -> (Void) in
                
                if response["code"].rawString() == "200" {
                    HTZUserAccount.shared.saveUserAcountInfoWithDict(dict: dict as [String : Any])
                    // 发送网络状态改变的通知
                    NotificationCenter.default.post(name: NSNotification.Name(kLoginSuccessNotification), object: nil)
                }
            }
        }
        
        
        
    }
    
}
