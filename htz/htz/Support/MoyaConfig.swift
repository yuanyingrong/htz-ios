//
//  MoyaConfig.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/29.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

/// 定义基础域名
let Moya_baseURL = "http://39.96.5.46:9100/"
let search_baseURL = "http://39.96.5.46:9300/"
let download_baseURL = "http://39.96.5.46:9400/"
//let Moya_baseURL = "http://htzshanghai.top/resources/app_json/"
let mobile_baseURL = "http://121.36.173.141:8888/api/"

let ossurl = "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/"

/// 定义返回的JSON数据字段
let RESULT_CODE = "flag"      //状态码

let RESULT_MESSAGE = "message"  //错误消息提示


/*  错误情况的提示
 {
 "flag": "0002",
 "msg": "手机号码不能为空",
 "lockerFlag": true
 }
 **/
