//
//  API.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/29.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import Moya

enum API {
    case albums
    case xingfuneixinchan
    case jingxinyangsheng
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
        case .song(_), .songDetail(_):
            return URL.init(string:"https://musicapi.qianqian.com/v1/restserver/ting?format=json&from=ios&channel=appstore&method=")!
        default:
            return URL.init(string:(Moya_baseURL))!
        }
    }
    
    var path: String {
        switch self {
        case .albums:
         return "albums.json"
        case .xingfuneixinchan:
            return "xingfuneixinchan/xingfuneixinchan.json"
        case .jingxinyangsheng:
            return "jingxinyangsheng/jingxinyangsheng.json"
        case .sinaOAuth(_):
            return "OAuth2/authorize"
        case let .song(type, size, offset):
            return "baidu.ting.billboard.billList&type=\(type)&size=\(size)&offset=\(offset)"
        case let .songDetail(songId):
            return "baidu.ting.song.play&songid=\(songId)"
        case .easyRequset:
            return "4/news/latest"
        case .uploadHeadImage( _):
            return "/file/user/upload.jhtml"
        default:
            return ""
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .easyRequset:
            return .get
        default:
            return .get
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
        
        case .albums, .xingfuneixinchan, .jingxinyangsheng, .song(_), .songDetail(_):
            return .requestPlain
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
        return ["Content-Type":"application/x-www-form-urlencoded"]
    }
    
}


extension TargetType {
    
}
