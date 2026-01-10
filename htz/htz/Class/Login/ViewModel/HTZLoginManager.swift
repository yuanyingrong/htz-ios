//
//  HTZLoginManager.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/26.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit
import Foundation

class HTZLoginManager: NSObject {
    
    static let shared = HTZLoginManager()
    
    func jumpToWechatLogin(controller: UIViewController) {
        HTZLog.info("LOGIN-MANAGER", "开始微信登录流程")
        let vc = HTZWechatLoginViewController()
        controller.navigationController?.pushViewController(vc, animated: true)
        vc.loginResult = { [weak self] loginModel in
            HTZLog.info("LOGIN-MANAGER", "登录结果回调执行，loginModel: \(loginModel != nil ? "存在" : "nil")")
            if let loginModel = loginModel {
                HTZLog.info("LOGIN-MANAGER", "微信登录成功，获取到登录模型数据")
                let dict:[String : Any?] = [
                    "token":loginModel.token,
                    "name":loginModel.name,
                    "id":loginModel.id,
                    "union_id":loginModel.union_id,
                    "mobile":loginModel.mobile,
                    "gender":loginModel.gender,
                    "created_at":loginModel.created_at,
                    "avatar":loginModel.avatar,
                    "birthday_year":loginModel.birthday_year,
                    "country":loginModel.wx_login_resp?.country,
                    "unionid":loginModel.wx_login_resp?.unionid,
                    "city":loginModel.wx_login_resp?.city,
                    "province":loginModel.wx_login_resp?.province,
                    "privilege":loginModel.wx_login_resp?.privilege,
                    "nickname":loginModel.wx_login_resp?.nickname,
                    "openid":loginModel.wx_login_resp?.openid,
                    "headimgurl":loginModel.wx_login_resp?.headimgurl]
                
                
                
                
                
                let param:[String : Any] = [
                                              "city": loginModel.wx_login_resp?.city ?? "",
                                              "country": loginModel.wx_login_resp?.country ?? "",
                                              "createTime": Date.getTime(timeStamp: loginModel.created_at ?? "", format: .dateYMDHMS),
                                              "group_id": "0", // Changed from groupId: 0 to group_id: "0"
                                              "headimgurl": loginModel.wx_login_resp?.headimgurl ?? "",
                                              "language": "",
                                              "lastUpdateTime": "",
                                              "nickname": loginModel.wx_login_resp?.nickname ?? "",
                                              "note": "",
                                              "openid": loginModel.wx_login_resp?.openid ?? "",
                                              "province": loginModel.wx_login_resp?.province ?? "",
                                              "pwd": "",
                                              "sex": String(loginModel.wx_login_resp?.sex ?? 0), // Converted to String
                                              "sign": "",
                                              "telephone": "",
                                              "unionid": loginModel.wx_login_resp?.unionid ?? ""
                                            ]
                
                HTZLog.debug("LOGIN-MANAGER", "正在上传用户信息到服务器")
                NetWorkRequest(API.addUserInfo(parameters: param)) { (response) -> (Void) in
                    
                    let responseCode = response["code"].rawString()
                    if responseCode == "200" || responseCode == "0" {
                        HTZLog.info("LOGIN-MANAGER", "用户信息上传成功，保存到本地")
                        HTZUserAccount.shared.saveUserAcountInfoWithDict(dict: dict as [String : Any])
                        // 发送网络状态改变的通知
                        NotificationCenter.default.post(name: NSNotification.Name(kLoginSuccessNotification), object: nil)
                        HTZLog.info("LOGIN-MANAGER", "微信登录成功并保存用户信息")
                    } else {
                        HTZLog.error("LOGIN-MANAGER", "添加用户信息失败: \(response["message"].stringValue)")
                        // 即使添加用户信息失败，也尝试发送登录成功通知
                        HTZUserAccount.shared.saveUserAcountInfoWithDict(dict: dict as [String : Any])
                        NotificationCenter.default.post(name: NSNotification.Name(kLoginSuccessNotification), object: nil)
                        HTZLog.warning("LOGIN-MANAGER", "尽管用户信息上传失败，仍触发登录成功通知")
                    }
                }
            } else {
                HTZLog.error("LOGIN-MANAGER", "微信登录失败，没有收到登录模型数据")
            }
        }
    }
    
}
