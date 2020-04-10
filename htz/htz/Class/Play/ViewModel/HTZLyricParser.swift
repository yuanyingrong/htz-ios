//
//  HTZLyricParser.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/12.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZLyricParser: NSObject {

    /// 歌词解析
    ///
    /// - Parameter url: 歌词的url
    /// - Returns: 包含歌词模型的数组
    static func lyricParser(url: String) -> [HTZLyricModel]? {
        
        // 根据歌词文件的url获取歌词内容
        do {
            let lyricStr = try String(contentsOf: URL(string: url)!, encoding: String.Encoding.utf8)
            return self.lyricParser(lyricString: lyricStr, isDelBlank: false)
        } catch  {
            print(error)
        }
        return nil
    }
    
    /// 歌词解析
    ///
    /// - Parameters:
    ///   - url: 歌词的url
    ///   - isDelBlank: 是否去掉空白行歌词
    /// - Returns: 包含歌词模型的数组
    static func lyricParser(url: String, isDelBlank: Bool) -> [HTZLyricModel]? {
        // 根据歌词文件的url获取歌词内容
        
        do {
            if url.hasPrefix("http") { // 网络路径
                let lyricStr = try String(contentsOf: URL(string: url)!, encoding: String.Encoding.utf8)
                return self.lyricParser(lyricString: lyricStr, isDelBlank: isDelBlank)
            } else { // 本地路径
                let lyricStr = try String(contentsOfFile: url, encoding: String.Encoding.utf8)
                return self.lyricParser(lyricString: lyricStr, isDelBlank: isDelBlank)
            }
            
        } catch  {
            print(error)
        }
        return nil
    }
    
    /// 歌词解析
    ///
    /// - Parameters:
    ///   - localPath: 歌词的本地路径
    ///   - isDelBlank: 是否去掉空白行歌词
    /// - Returns: 包含歌词模型的数组
    static func lyricParser(localPath: String, isDelBlank: Bool) -> [HTZLyricModel]? {
        // 根据歌词文件的url获取歌词内容
        do {
            let lyricStr = try String(contentsOf: URL(fileURLWithPath: localPath), encoding: String.Encoding.utf8)
            return self.lyricParser(lyricString: lyricStr, isDelBlank: isDelBlank)
        } catch  {
            print(error)
        }
        return nil
    }
    
    /// 歌词解析
    ///
    /// - Parameter str: 所有歌词的字符串
    /// - Returns: 包含歌词模型的数组
    static func lyricParser(str: String) -> [HTZLyricModel]? {
        
        return self.lyricParser(lyricString: str, isDelBlank: false)
    }
    
    /// 歌词解析
    ///
    /// - Parameters:
    ///   - lyricString: 歌词对应的字符串
    ///   - isDelBlank: 是否去掉空白行歌词
    /// - Returns: 包含歌词模型的数组
    static func lyricParser(lyricString: String, isDelBlank: Bool) -> [HTZLyricModel]? {
        // 1. 以\n分割歌词
        let linesArr = lyricString.components(separatedBy: "\n")
        
        // 2. 创建模型数组
        var modelArr = [HTZLyricModel]()
        
        // 3. 开始解析
        // 由于有形如
        // [ti:如果没有你]
        // [00:00.64]歌词
        // [00:01.89][03:01.23][05:03.43]歌词
        // [00:00.8]
        // 这样的歌词形式，所以最好的方法是用正则表达式匹配 [00:00.00] 来获取时间
        
        for line in linesArr {
            // 正则表达式
            let pattern = "\\[[0-9][0-9]:[0-9][0-9].[0-9]{1,}\\]"
            
            do {
                let regular = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
                // 进行匹配
                let matchesArr = regular.matches(in: line, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange(location: 0, length: line.count))
                // 获取歌词部分
                // 方法一
                //        NSTextCheckingResult *match = matchesArray.lastObject;
                //
                //        NSString *content = [line substringFromIndex:(match.range.location + match.range.length)];
                
                // 方法二  [00:01.78]歌词
                let content = line.components(separatedBy: "]").last
                
                 // 获取时间部分[00:00.00]
                for match in matchesArr {
                    
                    var timeStr = line[Range(match.range)!]
                    
                    // 去掉开头和结尾的[],得到时间00:00.00
                    // 去掉[
                    timeStr = timeStr.substring(fromIndex: 1)
                    // 去掉]
                    timeStr = timeStr.substring(toIndex: timeStr.count - 1)
                    
                    // 分、秒、毫秒
                    let minStr = timeStr[Range(NSRange(location: 0, length: 2))!]
                    let secStr = timeStr[Range(NSRange(location: 3, length: 2))!]
                    
                    // 由于毫秒有一位或者两位，所以应从小数点（第六位）后获取
                    let mseStr = timeStr.substring(fromIndex: 6)
                    
                    // 转换成以毫秒秒为单位的时间 1秒 = 1000毫秒
                    let time = TimeInterval(minStr)! * 60 * 1000 + TimeInterval(secStr)! * 1000 + TimeInterval(mseStr)!
                    
                    // 创建模型，赋值
                    let lyricModel = HTZLyricModel()
                    lyricModel.content = content
                    lyricModel.msTime = time
                    lyricModel.secTime = time / 1000
                    lyricModel.timeString = HTZMusicTool.timeStr(msTime: time)
                    modelArr.append(lyricModel)
                }
            } catch {
                print(error)
            }
        }
        
        // 去掉空白行歌词
        if isDelBlank {
            for (idx, obj) in modelArr.enumerated() {
                if obj.content == nil || obj.content == "" {
                    modelArr.remove(at: idx)
                    
                }
            }
        }
        
        // 数组根据时间进行排序 时间（time）
        // ascending: 是否升序
//        let descriptor = NSSortDescriptor(key: "msTime", ascending: true)
        return modelArr
//        return modelArr.sorted { (obj1, obj2) -> Bool in
//            return obj1.msTime! < obj2.msTime!
//        }
    }
}
