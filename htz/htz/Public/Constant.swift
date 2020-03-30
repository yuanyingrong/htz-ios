//
//  Constant.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import Foundation

class Constant: NSObject {

}

//判断系统
let IOS7 = Int(UIDevice.current.systemVersion)! >= 7 ? true : false;
let IOS8 = Int(UIDevice.current.systemVersion)! >= 8 ? true : false;
let IOS9 = Int(UIDevice.current.systemVersion)! >= 9 ? true : false;
let IOS11 = Int(UIDevice.current.systemVersion)! >= 11 ? true : false;

//UIColor
let kTableVBackColor = UIColor.colorWithHexString("#eeeeee")
let kCollectionVBackColor = UIColor.colorWithHexString("#eeeeee")
let kScreenWidth = UIScreen.main.bounds.width
let kScreenHeight = UIScreen.main.bounds.height


// 自定义打印方法
func printLog<T>(_ message : T, file : String = #file, funcName : String = #function, lineNum : Int = #line) {
    
    #if DEBUG
    
    let fileName = (file as NSString).lastPathComponent
    
    print("\(fileName):(\(lineNum)) \(message)")
    
    #endif
}
let kNetworkChangeNotification = "kNetworkChangeNotification" // 网络状态改变
let kPlayStateChangeNotification = "kPlayStateChangeNotification" // 播放状态改变
let kLoveMusicNotification = "kLoveMusicNotification" // 喜欢音乐
let kPlayMusicChangeNotification = "kPlayMusicChangeNotification" // 播放数据改变
let kLoginSuccessNotification = "kLoginSuccessNotification" // 登录成功

struct UserDefaults {
    static let Standard = Foundation.UserDefaults.standard
    static let keyNetworkState = "networkState" // 网络状态
    static let keyPlayStyle = "playStyle" // 播放类型
    static let keyLastPlayId = "lastPlayId" // 上一次播放id
    static let keyPlayInfo = "playInfo" // 播放信息
    
     static let keyUserAccount = "keyUserAccount" 
    
    static let keySavedImageUserProfile = "NSUSERDEFAULT_KEY_IMAGE_CURRENT_USER"
    static let keySavedFirstName = "NSUSERDEFAULT_KEY_FIRST_NAME"
    static let keySavedLastName = "NSUSERDEFAULT_KEY_LAST_NAME"
    static let keySavedMiddleName = "NSUSERDEFAULT_KEY_MIDDLE_NAME"
    static let keySavedAccessToken = "NSUSERDEFAULT_KEY_ACCESS_TOKEN"
    static let keySavedUserEmail = "NSUSERDEFAULT_KEY_EMAIL"
    static let keySavedFullName = "NSUSERDEFAULT_KEY_FULL_NAME"
    static let keySavedLinkedin = "NSUSERDEFAULT_KEY_LINKEDIN"
    static let keySavedCompany  = "NSUSERDEFAULT_KEY_COMPANY"
    static let keySavedContact = "NSUSERDEFAULT_KEY_CONTACT"
    static let keySavedCountry = "NSUSERDEFAULT_KEY_COUNTRY"
    
    static let keyUID  = "NSUSERDEFAULT_KEY_UID"
    static let keyIsLoggedIn = "isLoggedIn"
    static let keyIsFirstLaunch = "FirstLaunch"
    static let keyIsSAC = "isSAC"
    static let keyIsSubscribed  = "isSubscribed"
    
    /*API headers*/
    static let keyHeaders                   = "HEADERS"
    static let firstLogin                   = "NSUSERDEFAULT_FIRST_LOGIN"
    static let keyBuildNum                  = "NSUSERDEFAULT_BUILD"
    /* app subscription */
    static let numberOfInteraction          = "NSUSERDEFAULT_INTERACTION"
    static let subscriptionTimeStamp           = "TIMESTAMP"
    static let numberOfViewsBlog            = "NSUSERDEFAULT_BLOG_VIEWS"
    static let numberOfLaunch               = "NSUSERDEFAULT_NUMBER_OF_LAUNCH"
    
}


struct cellIdentifier {
    /* insert your default identifer */
    
    static let menu                     = "cell_menu"
    
    
    /** news detail**/
    static let news_detail_image        = "cell_image"
    
    
    
    
    /* CustomCellForm ID */
    static let label_textfield_v2 = "cell_label_textfield_v2"
    
    
    /* More */
    static let cellTableViewImageTitle = "cell_image_title"
}


struct xibName {
    static let categoryCollectionViewCell =  "CategoryCollectionViewCell"
    
    
    
    /* custom loader */
    static let customLoader = "CustomLoader"
    
}


struct restorationId{
    /* custom loader */
    static let customLoaderResID = "customLoaderRestoration"
    
}


struct segueIdentifier{
    /* insert your default identifer */
    
    static let news_details                 = "segue_news_detail"
    static let login                        = "segue_login"
    static let profile                      = "segue_profile"
    static let web_view                     = "segue_web_view"
    static let privacy_policy               = "segue_privacy"
    
    static let to_Tour                      = "toTourSegue"
    
    /** drawer slider **/
    static let menu_drawer_home             = "Home"
    static let menu_drawer_member           = "segue_member"
    
    
    static let to_event_detail              = "toEventDetailsSegue"
    static let to_event_detail_form         = "toEventInnerFormSegue"
    
    /* Event Details */
    static let event_attendees              = "attendeesContainerSegue"
    static let event_info                   = "infoContainerSegue"
    
    static let login_registration           = "registration"
    /* Portfolio */
    static let splash_to_second             = "to_splash_2"
    static let to_portfolio                 = "seguePortfolio"
    static let to_portfilio_detail          = "to_portfolio_detail"
    static let to_portfolio_zoom            = "segue_to_zoomable_collection"
    /* feedback */
    static let to_feeback_view              = "to_feedback_view"
    /* login view */
    static let to_registration_view         = "to_registration"
    /* forgot password */
    static let to_forgot_password           = "to_forgotpassword"
    /*  blog inner */
    static let to_blog_inner                = "toBlogInner"
}


struct storyBoardViewIdentifier{
    /* insert your default identifer */
    
    static let splash_1                     = "root"
    
}
struct storyBoardName{
    static let main                         = "Main"
    
}

struct apiUrl {
    
    /*
     API URLs
     */
    
    static let base_url_staging    = "http://staging.URL.com/api/v1/"
    static let base_url_     = "http://sac-app.URL.com/api/v1/"
    static let dev = "http://dev.sac-app.URL.com/api/v1/"
    static let prod = "http://sac-app.URL.com/api/v1/"/**/
    static let uat = "http://uat.sac-app.URL.com/api/v1/"
    /* insert your Link */
    static let base_url     = dev
    
    static let dev_registration = "http://dev.sac-app.URL.com/api/v1/"
    static let prod_registration = "http://sac-app.URL.com/api/v1/"/**/
    static let uat_registration = "http://uat.sac-app.URL.com/api/v1/"
    static let registraion = prod_registration
    
    static let dev_forgot_pass = "http://dev.sac-app.URL.com/"
    static let prod_forgot_pass = "http://sac-app.URL.com/"/**/
    static let uat_forgot_pass = "http://uat.sac-app.URL.com/"
    static let base_url_web = prod_forgot_pass
    
    
    static let news         = "news"
    
    
}
struct navigationBar {
    //sample font
    //    static let primaryBackroundColor    = UIColor.white
    //    static let primaryFontColor         = customColor.tintBlack
    //    static let fontBar                  = UIFont(name: "MyriadPro-Bold", size: 20)!
}

struct fonts {
    //sample font
    static let fontHeading1               = UIFont(name: "MyriadPro-Bold", size: 20)!
    static let fontHeading2               = UIFont(name: "MyriadPro-Bold", size: 20)!
    static let fontHeading3               = UIFont(name: "MyriadPro-Bold", size: 20)!
    static let fontHeading4               = UIFont(name: "MyriadPro-Bold", size: 20)!
    static let fontHeading5               = UIFont(name: "MyriadPro-Bold", size: 20)!
    static let fontHeading6               = UIFont(name: "MyriadPro-Bold", size: 27)! //Title header
}

struct customColor {
    //    static let darkBlue         = UIColor(red: 0/255, green: 41/255, blue: 87/255, alpha: 1.0)
}
