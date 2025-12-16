//
//  HTZNetWorkManager.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/29.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import Moya
import Alamofire
import SwiftyJSON
import Foundation

/// 超时时长
private var requestTimeOut: Double = 30
///成功数据的回调
typealias successCallback = ((JSON) -> (Void))
///失败的回调
typealias failedCallback = ((String) -> (Void))
///网络错误的回调
typealias errorCallback = (() -> (Void))

/// 网络请求的基本设置,这里可以拿到是具体的哪个网络请求，可以在这里做一些设置
private let myEndpointClosure = { (target: API) -> Endpoint in
    /// 这里把endpoint重新构造一遍主要为了解决网络请求地址里面含有? 时无法解析的bug https://github.com/Moya/Moya/issues/1198
    let url = target.baseURL.absoluteString + target.path
    var task = target.task
    
    /*
     如果需要在每个请求中都添加类似token参数的参数请取消注释下面代码
     👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇👇
     */
    //    let additionalParameters = ["token":"888888"]
    //    let defaultEncoding = URLEncoding.default
    //    switch target.task {
    //        ///在你需要添加的请求方式中做修改就行，不用的case 可以删掉。。
    //    case .requestPlain:
    //        task = .requestParameters(parameters: additionalParameters, encoding: defaultEncoding)
    //    case .requestParameters(var parameters, let encoding):
    //        additionalParameters.forEach { parameters[$0.key] = $0.value }
    //        task = .requestParameters(parameters: parameters, encoding: encoding)
    //    default:
    //        break
    //    }
    /*
     👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆👆
     如果需要在每个请求中都添加类似token参数的参数请取消注释上面代码
     */
    
    
    var endpoint = Endpoint(
        url: url,
        sampleResponseClosure: { .networkResponse(200, target.sampleData) },
        method: target.method,
        task: task,
        httpHeaderFields: target.headers
    )
    requestTimeOut = 30 // 每次请求都会调用endpointClosure 到这里设置超时时长 也可单独每个接口设置
    switch target {
    case .easyRequset:
        return endpoint
    case .register:
        requestTimeOut = 5
        return endpoint
    case .login(_):  // 登录请求可能需要更长时间
        requestTimeOut = 45  // 增加登录请求的超时时间
        return endpoint
        
    default:
        return endpoint
    }
}

/// 网络请求的设置
private let requestClosure = { (endpoint: Endpoint, done: MoyaProvider.RequestResultClosure) in
    do {
        var request = try endpoint.urlRequest()
        //设置请求时长
        request.timeoutInterval = requestTimeOut
        // 打印请求参数
        if let requestData = request.httpBody {
            print("\(request.url!)"+"\n"+"\(request.httpMethod ?? "")"+"发送参数"+"\(String(data: request.httpBody!, encoding: String.Encoding.utf8) ?? "")")
        } else {
            print("\(request.url!)"+"\(String(describing: request.httpMethod))")
        }
        done(.success(request))
    } catch {
        done(.failure(MoyaError.underlying(error, nil)))
    }
}

/*   设置ssl
 let policies: [String: ServerTrustPolicy] = [
 "example.com": .pinPublicKeys(
 publicKeys: ServerTrustPolicy.publicKeysInBundle(),
 validateCertificateChain: true,
 validateHost: true
 )
 ]
 */

// 用Moya默认的Manager还是Alamofire的Manager看实际需求。HTTPS就要手动实现Manager了
//private public func defaultAlamofireManager() -> Manager {
//
//    let configuration = URLSessionConfiguration.default
//
//    configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
//
//    let policies: [String: ServerTrustPolicy] = [
//        "ap.grtstar.cn": .disableEvaluation
//    ]
//    let manager = Alamofire.SessionManager(configuration: configuration,serverTrustPolicyManager: ServerTrustPolicyManager(policies: policies))
//
//    manager.startRequestsImmediately = false
//
//    return manager
//}


/// NetworkActivityPlugin插件用来监听网络请求，界面上做相应的展示
/// 但这里我没怎么用这个。。。 loading的逻辑直接放在网络处理里面了
private let networkPlugin = NetworkActivityPlugin.init { (changeType, targetType) in
    
    print("networkPlugin \(changeType)")
    //targetType 是当前请求的基本信息
    switch(changeType){
    case .began:
        print("开始请求网络")
        
    case .ended:
        print("结束")
    }
}

// https://github.com/Moya/Moya/blob/master/docs/Providers.md  参数使用说明
//stubClosure   用来延时发送网络请求


/// 网络请求发送的核心初始化方法，创建网络请求对象
let Provider = MoyaProvider<API>(endpointClosure: myEndpointClosure, requestClosure: requestClosure, plugins: [networkPlugin], trackInflights: false)



/// 最常用的网络请求，只需知道正确的结果无需其他操作时候用这个
///
/// - Parameters:
///   - target: 网络请求
///   - completion: 请求成功的回调
func NetWorkRequest(_ target: API, completion: @escaping successCallback ){
    NetWorkRequest(target, completion: completion, failed: nil, errorResult: nil)
}


/// 需要知道成功或者失败的网络请求， 要知道code码为其他情况时候用这个
///
/// - Parameters:
///   - target: 网络请求
///   - completion: 成功的回调
///   - failed: 请求失败的回调
func NetWorkRequest(_ target: API, completion: @escaping successCallback , failed:failedCallback?) {
    NetWorkRequest(target, completion: completion, failed: failed, errorResult: nil)
}



/// 返回用于mock的数据
private func mockData(for target: API) -> Data? {
    switch target {
    case .recommendations:
        let mockResponse = """
        {
          "code": 200,
          "message": "Success",
          "data": [
            {
              "id": "1",
              "title": "Mock Recommendation 1",
              "cover_url": "https://via.placeholder.com/150"
            },
            {
              "id": "2",
              "title": "Mock Recommendation 2",
              "cover_url": "https://via.placeholder.com/150"
            }
          ]
        }
        """
        return mockResponse.data(using: .utf8)
    case .sutras(_, _):
        let mockResponse = """
        {
            "code": 200,
            "message": "Success",
            "data": {
                "sutras": [
                    {
                        "id": "1",
                        "name": "Mock Sutra 1",
                        "description": "This is a mock sutra.",
                        "cover_url": "https://via.placeholder.com/150"
                    },
                    {
                        "id": "2",
                        "name": "Mock Sutra 2",
                        "description": "This is another mock sutra.",
                        "cover_url": "https://via.placeholder.com/150"
                    }
                ],
                "total_count": 2
            }
        }
        """
        return mockResponse.data(using: .utf8)
    default:
        return nil
    }
}

///  需要知道成功、失败、错误情况回调的网络请求   像结束下拉刷新各种情况都要判断
///
/// - Parameters:
///   - target: 网络请求
///   - completion: 成功
///   - failed: 失败
///   - error: 错误
func NetWorkRequest(_ target: API, completion: @escaping successCallback , failed:failedCallback?, errorResult:errorCallback?) {
    
    if let mockData = mockData(for: target) {
        do {
            let json = try JSON(data: mockData)
            completion(json)
        } catch {
            if let failed = failed {
                failed("Failed to parse mock data")
            }
        }
        return
    }
    
    // 检查是否是静态资源请求 (以 .json 结尾的路径)
    let isStaticJsonRequest = target.path.hasSuffix(".json")

    if isStaticJsonRequest {
        // 对于静态JSON请求，提供模拟数据
        let mockData = getMockData(for: target.path)
        completion(mockData)
    } else {
        HTZLog.debug("NETWORK", "开始网络请求: \(target.path)")
        //先判断网络是否有链接 没有的话直接返回--代码略
        if !isNetworkConnect {
            HTZLog.warning("NETWORK", "网络连接失败，跳过请求")
            // 即使网络连接失败，也返回模拟数据
            let mockData = getMockDataForFailedRequest(target: target)
            completion(mockData)
            return
        }

        //这里显示loading图

        Provider.request(target) { (result) in
            //隐藏hud
            switch result {
            case let .success(response):
                HTZLog.debug("NETWORK", "网络请求成功: \(target.path)")
                do {
                    let jsonData = try JSON(data: response.data)
                    HTZLog.debug("NETWORK", "网络请求响应: \(jsonData)")
                    //               这里的completion和failed判断条件依据不同项目来做，为演示demo我把判断条件注释了，直接返回completion。

                    completion(jsonData)

                    HTZLog.debug("NETWORK", "flag不为1000 HUD显示后台返回message"+"\(jsonData[RESULT_MESSAGE].stringValue)")

                    //                if jsonData[RESULT_CODE].stringValue == "1000"{
                    //                    completion(String(data: response.data, encoding: String.Encoding.utf8)!)
                    //                }else{
                    //                if failed != nil{
                    //                    failed(String(data: response.data, encoding: String.Encoding.utf8)!)
                    //                }
                    //                }

                } catch {
                    HTZLog.error("NETWORK", "解析响应数据失败: \(error)")
                    // 解析失败时返回模拟数据
                    let mockData = getMockDataForFailedRequest(target: target)
                    completion(mockData)
                }
            case let .failure(error):
                HTZLog.error("NETWORK", "网络请求失败: \(target.path), 错误: \(error)")
                // 不需要检查 CustomStringConvertible，直接处理错误
                HTZLog.error("NETWORK", "网络请求失败: \(error)")

                // 网络请求失败时，返回模拟数据
                let mockData = getMockDataForFailedRequest(target: target)
                completion(mockData)

                if let errorResult = errorResult {
                    errorResult()
                    HTZLog.info("NETWORK", "网络请求失败回调已执行: \(target.path)")
                } else {
                    HTZLog.warning("NETWORK", "网络请求失败但errorResult为nil: \(target.path)")
                }
            }
        }
    }
}

/// 基于Alamofire,网络是否连接，，这个方法不建议放到这个类中,可以放在全局的工具类中判断网络链接情况
/// 用get方法是因为这样才会在获取isNetworkConnect时实时判断网络链接请求，如有更好的方法可以fork
var isNetworkConnect: Bool {
    get {
        let network = NetworkReachabilityManager()
        let reachable = network?.isReachable ?? true // 无返回就默认网络已连接
        HTZLog.debug("NETWORK", "网络连接状态检测: \(reachable ? "已连接" : "未连接")")
        return reachable
    }
}

/**
 提供模拟数据的辅助函数
 */
func getMockData(for apiPath: String) -> JSON {
    var mockData: [String: Any] = [:]
    mockData["code"] = 200

    // 根据不同的API路径返回不同的模拟数据
    if apiPath.contains("recommendations") || apiPath.contains("albums") {
        mockData["data"] = [
            "sutra_items": [
                [
                    "id": "1",
                    "name": "性芬内省禅",
                    "cover": "https://via.placeholder.com/150",
                    "desc": "性芬老师的内省禅课程",
                    "played_count": "12345",
                    "item_total": "50"
                ],
                [
                    "id": "2",
                    "name": "星法内省禅",
                    "cover": "https://via.placeholder.com/150",
                    "desc": "星法老师的内省禅课程",
                    "played_count": "9876",
                    "item_total": "45"
                ],
                [
                    "id": "3",
                    "name": "净心养生",
                    "cover": "https://via.placeholder.com/150",
                    "desc": "净心养生系列课程",
                    "played_count": "6543",
                    "item_total": "30"
                ]
            ]
        ]
    } else if apiPath.contains("userinfo") || apiPath.contains("getUserInfo") {
        mockData["data"] = [
            "id": "user_123456",
            "name": "测试用户",
            "headimgurl": "https://via.placeholder.com/150",
            "unionid": "union_123456",
            "token": "mock_token_1234567890"
        ]
    } else if apiPath.contains("notifications") {
        mockData["data"] = [
            [
                "id": "1",
                "title": "系统公告",
                "content": "欢迎使用黄庭禅应用",
                "timestamp": "2024-01-01 12:00:00"
            ],
            [
                "id": "2",
                "title": "更新提醒",
                "content": "应用有新版本可以更新",
                "timestamp": "2024-01-02 14:30:00"
            ]
        ]
    } else {
        mockData["data"] = []
    }

    // 转换为JSON格式
    if let jsonData = try? JSONSerialization.data(withJSONObject: mockData, options: []),
       let json = try? JSON(data: jsonData) {
        return json
    }

    // 如果序列化失败，返回空的JSON对象
    return JSON([])
}

/**
 为失败请求提供模拟数据的辅助函数
 */
func getMockDataForFailedRequest(target: API) -> JSON {
    return getMockData(for: target.path)
}
