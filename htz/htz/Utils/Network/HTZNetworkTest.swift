//
//  HTZNetworkTest.swift
//  htz
//
//  Created by 黄庭禅 on 2025.
//  Copyright © 2025 黄庭禅. All rights reserved.
//

import Foundation
import Alamofire

public class HTZNetworkTest {
    
    // 测试服务器连通性
    public static func testServerConnectivity(completion: @escaping (Bool, String?) -> Void) {
        let testUrl = "http://39.96.5.46:9100/"
        
        HTZLog.info("NETWORK-TEST", "开始测试服务器连通性: \(testUrl)")
        
        // 使用Alamofire测试连通性
        let request = AF.request(testUrl, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
        
        request.response(queue: DispatchQueue.global(qos: .background)) { response in
            DispatchQueue.main.async {
                if let error = response.error {
                    HTZLog.error("NETWORK-TEST", "服务器连通性测试失败: \(error)")
                    completion(false, "服务器连接失败: \(error)")
                } else {
                    HTZLog.info("NETWORK-TEST", "服务器连通性测试成功，状态码: \(String(describing: response.response?.statusCode))")
                    completion(true, nil)
                }
            }
        }
    }
    
    // 测试微信登录端点的连通性
    public static func testWeChatLoginEndpoint(code: String, completion: @escaping (Bool, String?) -> Void) {
        let testUrl = "http://39.96.5.46:9100/post/login"
        let parameters = ["code": code]
        
        HTZLog.info("NETWORK-TEST", "开始测试微信登录端点: \(testUrl), code: \(code)")
        
        let request = AF.request(testUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json"])
        
        request.response(queue: DispatchQueue.global(qos: .background)) { response in
            DispatchQueue.main.async {
                if let error = response.error {
                    HTZLog.error("NETWORK-TEST", "微信登录端点测试失败: \(error)")
                    completion(false, "微信登录端点连接失败: \(error)")
                } else {
                    HTZLog.info("NETWORK-TEST", "微信登录端点测试完成，状态码: \(String(describing: response.response?.statusCode))")
                    if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                        HTZLog.debug("NETWORK-TEST", "微信登录端点响应: \(responseString)")
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    // 检查网络状态
    public static func checkNetworkStatus() -> String {
        let network = NetworkReachabilityManager()
        let reachable = network?.isReachable ?? false
        
        var type = "未知"
        if let network = network {
            if network.isReachableOnCellular {
                type = "蜂窝网络"
            } else if network.isReachableOnEthernetOrWiFi {
                type = "WiFi"
            }
        }
        
        let status = reachable ? "已连接(\(type))" : "未连接"
        HTZLog.info("NETWORK-TEST", "当前网络状态: \(status)")
        
        return status
    }
}