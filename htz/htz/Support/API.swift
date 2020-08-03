//
//  API.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/29.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import Moya
import Alamofire

enum API {
    case login(code: String)
    case sutras(page_index: NSInteger, page_size: NSInteger)
    case es_search(key: String)
    case search(key: String, output_offset: NSInteger, max_outputs: NSInteger)
    case item(id: String) // 查询单个经典信息
    case items(sutra_id: String, page_index: NSInteger, page_size: NSInteger) // 查询多条经典items
    case download(file_id: String, fileLocalPath: String) // 下载
    
    case postListenHistory(parameters: [String:Any]) // 添加收听记录
    case deleteListenHistory(id: String) // 删除单条收听记录
    case deleteAllListenHistory // 删除所有收听记录
    case getListenHistorys(page_index: NSInteger, page_size: NSInteger) // 获取收听记录
    
    case recommendations // 经典推荐列表
    
    case userNotifications // 获取我的通知信息 TODO
    case putNotification // 设置我的通知信息状态为已读 TODO
    case notifications(page_index: NSInteger, page_size: NSInteger)  // 查询所有通知
    
    case addUserInfo(parameters: [String: Any])
    case updateUserInfo(parameters: [String: Any])
    case getUserInfo
    case getSmsCode(telephone: String)
    case bindTelephone(code: String, telephone: String)
    
    case albums
    case xingfuneixinchan
    case jingxinyangsheng
    case mixinxiaoshipin
    
    case song(type: String, size: String, offset: String)
    case songDetail(songId: String)
    case sinaOAuth(code: String)
    case register(email:String,password:String)
    //上传用户头像
    case uploadHeadImage(parameters: [String:Any],imageDate:Data)
    case easyRequset
}

extension API: TargetType {
    var baseURL: URL {
        switch self {
        case .sinaOAuth:
            return URL.init(string:"https://api.weibo.com/")!
//        case .song(_), .songDetail(_):
//            return URL.init(string:"https://musicapi.qianqian.com/v1/restserver/ting?format=json&from=ios&channel=appstore&method=")!
        case .search(_,_,_):
            return URL(string: search_baseURL)!
        case .download(_,_):
            return URL(string: download_baseURL)!
        case .addUserInfo(_), .updateUserInfo(_), .getUserInfo, .getSmsCode(_), .bindTelephone(_,_):
            return URL(string: mobile_baseURL)!
        case .albums, .xingfuneixinchan, .jingxinyangsheng, .mixinxiaoshipin:
            return URL(string: "http://htzshanghai.top/resources/app_json/")!
        default:
            return URL.init(string:(Moya_baseURL))!
        }
    }
    
    var path: String {
        switch self {
        case .login(_):
            return "post/login"
        case .sutras(_,_):
            return "get/sutras"
        case .es_search(_):
            return "es/htz-sutra/_search"
        case .search(_,_,_):
            return "get/search"
        case .items(_,_,_):
            return "get/sutra/items"
        case .item(_):
            return "get/sutra/item"
        case .download(_,_):
            return "get/download"
           
            
        case .postListenHistory(_): // 添加收听记录
            return "post/listen/history"
        case .deleteListenHistory(_): // 删除单个收听记录
            return "delete/listen/history"
        case .deleteAllListenHistory: // 删除个人所有收听记录
            return "delete/listen/histories/all"
        case .getListenHistorys(_,_): // 获取收听记录
            return "get/listen/histories"
        case .recommendations: // 经典推荐列表
            return "get/recommendations"
        case .userNotifications: // 获取我的通知信息 TODO
            return "get/user/notifications"
        case .putNotification: // 设置我的通知信息状态为已读 TODO
            return "put/user/notifications"
        case .notifications(_,_): // 查询所有通知
            return "get/notifications"

        case .addUserInfo(_):
            return "userInfo/add"
        case .updateUserInfo(_):
            return "userInfo/update"
        case .getUserInfo:
            return "userInfo/info/\(HTZUserAccount.shared.unionid!)"
        case .getSmsCode(_):
            return "telephone/getSmsCode"
        case .bindTelephone(_,_):
            return "telephone/bindTelephone"
            
        case .albums:
         return "albums.json"
        case .xingfuneixinchan:
            return "xingfuneixinchan/xingfuneixinchan.json"
        case .jingxinyangsheng:
            return "jingxinyangsheng/jingxinyangsheng.json"
        case .mixinxiaoshipin:
            return "mixinxiaoshipin/mixinxiaoshipin_old.json"
        case .sinaOAuth(_):
            return "OAuth2/authorize"
        case let .song(type, size, offset):
            return "baidu.ting.billboard.billList&type=\(type)&size=\(size)&offset=\(offset)"
        case let .songDetail(songId):
            return "baidu.ting.song.play&songid=\(songId)"
        case .easyRequset:
            return "4/news/latest"
        case .uploadHeadImage(parameters: _, imageDate: _):
            return "/file/user/upload.jhtml"
        default:
            return ""
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .es_search(_), .getUserInfo, .easyRequset, .albums, .xingfuneixinchan, .jingxinyangsheng, .mixinxiaoshipin:
            return .get
        default:
            return .post
        }
    }
    
    
    // 这个是做单元测试模拟的数据，必须要实现，只在单元测试文件中有作用
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
    
    // 该条请API求的方式,把参数之类的传进来
    var task: Task {
        //        return .requestParameters(parameters: nil, encoding: JSONArrayEncoding.default)
        switch self {
        case let .login(code):
            return .requestParameters(parameters: ["code": code], encoding: JSONEncoding.default)
        case let .postListenHistory(parameters), let .addUserInfo(parameters), let .updateUserInfo(parameters):
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .sutras(page_index, page_size), let .getListenHistorys(page_index, page_size), let .notifications(page_index, page_size):
            return .requestParameters(parameters: ["page_index" : page_index,"page_size":page_size], encoding: JSONEncoding.default)
        case let .es_search(key):
            return .requestParameters(parameters: ["query":["wildcard":["explanation":key]]], encoding: JSONEncoding.default)
        case let .search(key, output_offset, max_outputs):
            return .requestParameters(parameters: ["key" : key, "output_offset" : output_offset, "max_outputs":max_outputs], encoding: JSONEncoding.default)
        case let .items(id, page_index, page_size):
            return .requestParameters(parameters: ["sutra_id" : id, "page_index" : page_index, "page_size" : page_size], encoding: JSONEncoding.default)

        case let .item(id), let .deleteListenHistory(id):
            return .requestParameters(parameters: ["id" : id], encoding: JSONEncoding.default)
        case let .download(file_id, fileLocalPath):
            return .downloadParameters(parameters: ["file_id" : file_id], encoding: JSONEncoding.default) { (url, response) -> (destinationURL: URL, options: DownloadRequest.Options) in
                return (URL(fileURLWithPath: fileLocalPath),[])
            }
//            return .requestParameters(parameters: ["file_id" : file_id], encoding: JSONEncoding.default)

        case .getUserInfo, .deleteAllListenHistory, .recommendations, .userNotifications, .putNotification, .albums, .xingfuneixinchan, .jingxinyangsheng, .mixinxiaoshipin, .song(_,_,_), .songDetail(_):
            return .requestPlain
            
        case let .getSmsCode(telephone):
            return .requestParameters(parameters: ["telephone": telephone, "unionid": HTZUserAccount.shared.unionid!], encoding: URLEncoding.queryString)
        case let .bindTelephone(code, telephone):
            return .requestParameters(parameters: ["code": code, "telephone": telephone, "unionid": HTZUserAccount.shared.unionid!], encoding: URLEncoding.queryString)
            
        case let .register(email, password):
            return .requestParameters(parameters: ["email": email, "password": password], encoding: JSONEncoding.default)
        case .easyRequset:
            return .requestPlain
//        case let .updateAPi(parameters):
//            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        //图片上传
        case .uploadHeadImage(let parameters, let imageDate):
            ///name 和fileName 看后台怎么说，   mineType根据文件类型上百度查对应的mineType
            let formData = MultipartFormData(provider: .data(imageDate), name: "file",
                                             fileName: "hangge.png", mimeType: "image/png")
            return .uploadCompositeMultipart([formData], urlParameters: parameters)
        case let .sinaOAuth(code):
            return .requestParameters(parameters: ["client_id": sinaAppKey,
                                                   "client_secret": sinaAppSecrect,
                                                   "grant_type": "authorization_code",
                                                   "code": code,
                                                   "redirect_uri": sinaRedirectURI], encoding: JSONEncoding.default)
        //可选参数https://github.com/Moya/Moya/blob/master/docs_CN/Examples/OptionalParameters.md
        //        case .users(let limit):
        //        var params: [String: Any] = [:]
        //        params["limit"] = limit
        //        return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
    }
    
    
    
    var headers: [String : String]? {
        HTZUserAccount.shared.token = "7dcc850e-a97b-5141-b704-c24a77f76664"
        if let token = HTZUserAccount.shared.token {
            return ["Content-Type" : "application/json","token" : token]
        }
        return ["Content-Type" : "application/json"]
    }
    
}
