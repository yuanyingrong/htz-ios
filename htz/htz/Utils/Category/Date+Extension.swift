//
//  Date+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation

enum DateConstants: String {
    case locationBr = "pt_BR"
    case dateTimeBr = "dd/MM/yyyy HH:mm:ss"
    case dateTimeBrHyphen = "dd-MM-yyyy HH:mm:ss"
    case dateBr = "dd/MM/yyyy"
    case dateBrHyphen = "dd-MM-yyyy"
    case dateYMD = "yyyy-MM-dd"
    case dateYMDHMS = "yyyy-MM-dd HH:mm:ss"
}

extension Date {
    
    static func constants(_ constants: DateConstants) -> String {
        return constants.rawValue
    }
    
    func toString(withFormat format: DateConstants) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Date.constants(.locationBr))
        formatter.dateFormat = format.rawValue
        
        return formatter.string(from: self)
    }
    
}
