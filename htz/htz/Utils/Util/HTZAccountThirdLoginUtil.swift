//
//  HTZAccountThirdLoginUtil.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/29.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

//OAuth
let sinaAppKey = "951738706"
let sinaAppSecrect = "7e8d59de270734ddce414cd0dc675df6"
let sinaRedirectURI = "https://api.weibo.com/oauth2/default.html"
let wbuserName = "dxusdcom@163.com"
let wbpassWord = "517517"

let qqAppID = "1109745735"
let qqAppKey = "mubtaqjG8tQ9Clvy"

let wxAppID = "wx411fef9024bd3b5b"
let wxAppSecrect = "01a0b78aeaec432cf778c6a37b40aa9c"
let wxAppKey = "mubtaqjG8tQ9Clvy"

enum ThirdLoginType {
    case weibo // 新浪微博
    case tencent // QQ
    case weixin // 微信
}

// 成功数据的回调
typealias ThirdLoginResultCallback = ((_ loginResult: HTZLoginModel?, _ error: String?) -> (Void))

class HTZAccountThirdLoginUtil: NSObject {

    override init() {
        super.init()
        setRegisterApps()
    }
    static let sharedInstance = HTZAccountThirdLoginUtil()
    
    private var tencentOAuth:TencentOAuth?
    
    private var resultCallback: ThirdLoginResultCallback?
    
    private func setRegisterApps() {
        // 注册Sina微博
//        WeiboSDK.registerApp(sinaAppKey)
        // 微信注册
        let res = WXApi.registerApp(wxAppID, universalLink:"https://39.96.5.46:9500/")
        printLog(res)
        #if DEBUG
        WeiboSDK.enableDebugMode(true)
        #endif
        // 注册QQ
//        tencentOAuth = TencentOAuth(appId: qqAppID, andDelegate: self)
    }
    
    func getUserInfo(loginType: ThirdLoginType, result: @escaping ThirdLoginResultCallback) {
    
        resultCallback = result
        
        if loginType == ThirdLoginType.weibo {
            let request = WBAuthorizeRequest.request() as? WBAuthorizeRequest
            request?.redirectURI = sinaRedirectURI
            WeiboSDK.send(request)
        } else if loginType == ThirdLoginType.tencent {
            tencentOAuth?.authorize([kOPEN_PERMISSION_GET_USER_INFO, kOPEN_PERMISSION_GET_SIMPLE_USER_INFO, kOPEN_PERMISSION_GET_INFO])
        } else if loginType == ThirdLoginType.weixin {
            // 先判断有无安装微信
            if WXApi.isWXAppInstalled() {
                let req = SendAuthReq()
                req.scope = "snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact"
                req.state = "LCRACMVVMRouter"
                req.openID = wxAppID
                WXApi.send(req)
            } else { CurrentViewControllerUtil.sharedInstance.getCurrentViewController()?.alert(message: "您的设备未安装微信")
                print("您的设备未安装微信")
            }
        }
    }
    
}

// MARK: TencentSessionDelegate
extension HTZAccountThirdLoginUtil: TencentSessionDelegate {
    
    internal func tencentDidLogin() {
        if let tencentOAuth = tencentOAuth {
            tencentOAuth.getUserInfo()
        }
    }
    
    internal func tencentDidNotLogin(_ cancelled: Bool) {
        
    }
    
    internal func tencentDidNotNetWork() {
        
    }
    
    internal func getUserInfoResponse(_ response: APIResponse!) {
        if let tencentOAuth = tencentOAuth, response.retCode == URLREQUEST_SUCCEED.rawValue {
            print(response.jsonResponse!)
            print("openId: \(tencentOAuth.openId!)")
//            let parameter = ["third_id" : tencentOAuth.openId, "third_name" : response.jsonResponse["nickname"], "third_image" : response.jsonResponse["figureurl_qq_2"], "access_token" : tencentOAuth.accessToken]
            let model = HTZLoginModel()
            model.name = response.jsonResponse["nickname"] as? String;
            model.wx_login_resp?.headimgurl = response.jsonResponse["figureurl_qq_2"] as? String;
            model.token = tencentOAuth.accessToken;
            if self.resultCallback != nil {
                self.resultCallback!(model, nil)
            }
        } else {
            resultCallback!(nil, "授权失败")
            print("登录失败")
        }
    }
    
}

// MARK: WXApiDelegate
extension HTZAccountThirdLoginUtil: WXApiDelegate {
    
    internal func onReq(_ req: BaseReq) {
        
    }
    
    internal func onResp(_ resp: BaseResp) {
        // 获取用户信息
        switch resp.errCode {
        case 0: // 用户同意
            let aresp = resp as! SendAuthResp
            getWeiXinUserInfo(code: aresp.code!)
        case -2: // 用户取消授权微信登录
            print("用户取消授权微信登录")
            resultCallback!(nil, "授权失败")
        case -4: // 用户拒绝授权
            resultCallback!(nil, "授权失败")
            print("用户授权微信登录")
        default:
            print(resp)
            resultCallback!(nil, "授权失败")
        }
    }
    private func getWeiXinUserInfo(code: String) {
        NetWorkRequest(API.login(code: code)) { (response) -> (Void) in
            print(response);
            if (response["code"].intValue == 200) {
                let dict = response["data"]
                let model = HTZLoginModel.deserialize(from: dict.rawString())
                if self.resultCallback != nil {
                    self.resultCallback!(model, nil)
                }
            }
            
        }
    }
    
    
//    private func getWeiXinUserInfo(code: String) {
//
//        let queue = OperationQueue()
//        var access_token: String = ""
//
//        let getAccessTokenOperation = BlockOperation.init {
//            let urlStr = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=\(wxAppID)&secret=\(wxAppSecrect)&code=\(code)&grant_type=authorization_code"
//            let url = URL(string: urlStr)
//            do {
//                let responseStr = try String.init(contentsOf: url!, encoding: String.Encoding.utf8)
//                let responseData = responseStr.data(using: String.Encoding.utf8)
//                let json = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.mutableContainers)
//                let dict = json as! Dictionary<String, Any>
//                access_token = dict["access_token"] as! String
//            } catch {
//                print(error)
//            }
//        }
//
//        let getUserInfoOperation = BlockOperation.init {
//            let urlStr = "https://api.weixin.qq.com/sns/userinfo?access_token=\(access_token)&openid=\(wxAppID)"
//            let url = URL(string: urlStr)
//            do {
//                let responseStr = try String.init(contentsOf: url!, encoding: String.Encoding.utf8)
//                let responseData = responseStr.data(using: String.Encoding.utf8)
//                let json = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.mutableContainers)
//                let dict = json as! Dictionary<String, Any>
//                let parameter = ["third_id" : dict["openid"], "third_name" : dict["nickname"], "third_image" : dict["headimgurl"], "access_token" : access_token]
//                OperationQueue.main.addOperation {
//                    if self.resultCallback != nil {
//                        self.resultCallback!(parameter as [String : Any], nil)
//                    }
//                }
//            } catch {
//                print(error)
//            }
//        }
//
//        getUserInfoOperation.addDependency(getAccessTokenOperation)
//
//        queue.addOperation(getAccessTokenOperation)
//        queue.addOperation(getUserInfoOperation)
//    }
}

// MARK: WeiboSDKDelegate
extension HTZAccountThirdLoginUtil: WeiboSDKDelegate,URLSessionDelegate {
    
    internal func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
        
    }
    
    internal func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        // 获取用户信息
        let authResponse = response as! WBAuthorizeResponse
        let access_token = authResponse.accessToken ?? ""
        let uid = authResponse.userID ?? ""
        print("accessToken \(access_token)")
        print("uid: \(uid)")
        if access_token.count > 0 {
            getWeiBoUserInfo(uid: uid, access_token: access_token)
        } else {
            resultCallback!(nil, "授权失败")
        }
        
    }
    
    private func getWeiBoUserInfo(uid: String, access_token: String) {
        let urlStr = "https://api.weibo.com/2/users/show.json?uid=\(uid)&access_token=\(access_token)&source=\(sinaAppKey)"
        let url = URL(string: urlStr)!
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue())
        // 创建任务
        let tast = session.dataTask(with: URLRequest(url: url)) { (data, response, error) in
            print(Thread.current)
            let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            let dict = json as! Dictionary<String, Any>
//            let parameter = ["third_id" : dict["idstr"], "third_name" : dict["screen_name"], "third_image" : dict["avatar_hd"], "access_token" : access_token]
            let model = HTZLoginModel()
            model.name = dict["screen_name"] as? String;
            model.wx_login_resp?.headimgurl = dict["avatar_hd"] as? String;
            model.token = access_token;
            OperationQueue.main.addOperation {
                if self.resultCallback != nil {
                    self.resultCallback!(model, nil)
                }
            }
        }
        
        // 启动任务
        tast.resume()
    }
}

