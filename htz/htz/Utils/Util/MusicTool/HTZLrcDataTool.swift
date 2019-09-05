//
//  HTZLrcDataTool.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/4.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZLrcDataTool: NSObject {
    
    static func getLrcData(fileName: String) -> [HTZLrcModel] {
        
        // 1.文件路径
        let path = Bundle.main.path(forResource: fileName, ofType: nil)
        if path == nil {
            return []
        }
        
        // 2.加载文件里面的内容
        var lrcContent = ""
        do {
            try lrcContent = String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        } catch {
            print(error)
            return []
        }
        
        // 3.解析歌词
        // 3.1 将歌词转成数组
        let lrcStrArray = lrcContent.components(separatedBy: "\n")
        
        // 歌词数组
        var lrcMs = [HTZLrcModel]()
        
        // 3.2处理歌词字符串数字, 把字符串转成歌词对象
        for lrcStr in lrcStrArray {
            // 过滤垃圾数据
            /*
             [ti:]
             [ar:]
             [al:]
             */
            let isNoUseData = lrcStr.contains(Character("[ti:")) || lrcStr.contains(Character("[ar:")) || lrcStr.contains(Character("[al:"))
            
            if !isNoUseData {
                let lrcModel = HTZLrcModel()
                lrcMs.append(lrcModel)
                
                // 解析 [00:00.89]传奇
                // 去掉 [
                let resultStr = lrcStr.replacingOccurrences(of: "[", with: "")
                
                // 把 00:00.89 和 传奇 取出
                let timeAndContent = resultStr.components(separatedBy: "]")
                
                // 解析
                if timeAndContent.count == 2 {
                    let time = timeAndContent[0]
                    lrcModel.beginTime = Date.getTimeInterval(formatTime: time)
                    let content = timeAndContent[1]
                    lrcModel.lrcStr = content
                } else if timeAndContent.count == 1 {
                    let time = timeAndContent[0]
                    lrcModel.beginTime = Date.getTimeInterval(formatTime: time)
                    lrcModel.lrcStr = nil
                }
            }
        }
        // 修改模型的结束时间
        let count = lrcMs.count
        for (index, _) in lrcMs.enumerated() {
            if index != count - 1 {
                lrcMs[index].endTime = lrcMs[index + 1].beginTime
            }
        }
        return lrcMs
    }
    
    static func getRow(currentTime: TimeInterval, lrcMs: [HTZLrcModel], completion:((_ row: NSInteger, _ lrcModel: HTZLrcModel)->())) {
        var row = 0
        var lrcModel = HTZLrcModel()
        
        for (index, lrc) in lrcMs.enumerated() {
            if currentTime >= lrc.beginTime! && currentTime <= lrc.endTime! {
                row = index
                lrcModel = lrc
                break
            }
        }
        completion(row, lrcModel)
    }

}
