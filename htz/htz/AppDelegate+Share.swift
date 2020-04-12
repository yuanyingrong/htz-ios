//
//  AppDelegate+Share.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/12.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import Foundation

extension AppDelegate {
    
    func configShare() {
        //推送代码
        let shareConfig = JSHARELaunchConfig()
        shareConfig.appKey = JAppKey
//        shareConfig.sinaWeiboAppKey = "374535501"
//        shareConfig.sinaWeiboAppSecret = "baccd12c166f1df96736b51ffbf600a2"
//        shareConfig.sinaRedirectUri = "https://www.jiguang.cn"
//        shareConfig.qqAppId = "1105864531"
//        shareConfig.qqAppKey = "glFYjkHQGSOCJHMC"
        shareConfig.weChatAppId = wxAppID
        shareConfig.weChatAppSecret = wxAppSecrect
//        shareConfig.facebookAppID = "1847959632183996"
//        shareConfig.facebookDisplayName = "JShareDemo"
//        shareConfig.twitterConsumerKey = "4hCeIip1cpTk9oPYeCbYKhVWi"
//        shareConfig.twitterConsumerSecret = "DuIontT8KPSmO2Y1oAvby7tpbWHJimuakpbiAUHEKncbffekmC"
//        shareConfig.jChatProAuth = "a7e2ce002d1a071a6ca9f37d"
        JSHAREService.setup(with: shareConfig)
        JSHAREService.setDebug(true)
    }
    
    
}

