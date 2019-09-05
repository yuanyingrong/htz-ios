//
//  HTZDownloadManager.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

let kDocumentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first

let kDownloadManager = HTZDownloadManager.sharedInstance

protocol HTZDownloadManagerDelegate: NSObjectProtocol {
    
    /// 下载状态改变
    ///
    /// - Parameters:
    ///   - downloadManager: <#downloadManager description#>
    ///   - downloadModel: <#downloadModel description#>
    ///   - state: <#state description#>
    func downloadChanged(downloadManager: HTZDownloadManager, downloadModel:HTZDownloadModel, state: HTZDownloadManagerState)
    
    /// 删除下载
    ///
    /// - Parameters:
    ///   - downloadManager: <#downloadManager description#>
    ///   - downloadArr: <#downloadArr description#>
    func removedDownloadArr(downloadManager: HTZDownloadManager, downloadArr: [HTZDownloadModel])
    
    /// 下载进度
    ///
    /// - Parameters:
    ///   - downloadManager: <#downloadManager description#>
    ///   - downloadModel: <#downloadModel description#>
    ///   - totalSize: <#totalSize description#>
    ///   - downloadSize: <#downloadSize description#>
    ///   - progress: <#progress description#>
    func downloadProgress(downloadManager: HTZDownloadManager, downloadModel:HTZDownloadModel, totalSize: NSInteger, downloadSize: NSInteger, progress: Float)
}

class HTZDownloadManager: NSObject {
    

    static let sharedInstance = HTZDownloadManager()
    
    private var isCanBreakpoint: Bool = false
    
    weak var delegate: HTZDownloadManagerDelegate?
    
    override init() {
        super.init()
        // 创建下载文件的保存路径
        _ = createDirWithPath(path: downloadDataDir())
    }
    
    // 设置是否支持断点续传，默认NO
    func setCanBreakpoint(isCan: Bool) -> Void {
        isCanBreakpoint = isCan
    }
    
    // 根据id判断文件是否下载完成
    func checkDownloadWithID(fileID: String) -> Bool {
        var isDownload = false
        for obj in downloadFileList() {
            if fileID == obj.fileID && obj.state == HTZDownloadManagerState.finished {
                isDownload = true
            }
        }
        return isDownload
    }
    
    // 根据id获取本地数据信息
    func modelWithID(fileID: String) -> HTZDownloadModel? {
        if checkDownloadWithID(fileID: fileID) {
            var model: HTZDownloadModel? = nil
            for obj in downloadFileList() {
                if fileID == obj.fileID {
                   model = obj
                }
            }
            return model
        }
        return nil
    }
    
    // 添加下载
    func addDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        // 新加入的模型，需要把状态改为等待下载中
        for obj in downloadArr {
            if obj.state != HTZDownloadManagerState.finished && obj.state != HTZDownloadManagerState.downloading {
                obj.state = HTZDownloadManagerState.waiting
            }
        }
    }
    
    // 删除下载
    func removeDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        
    }
    
    // 暂停下载
    func pausedDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        
    }
    
    // 继续下载
    func resumeDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        
    }
    
    /// 遍历文件（全部）
    func downloadFileList() -> [HTZDownloadModel] {
        if ifPathExist(path: downloadDataFilePath()) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: downloadDataFilePath()) as! [HTZDownloadModel]
        }
        return []
    }
    
    /// 遍历文件（已下载）
    func downloadedFileList() -> [HTZDownloadModel] {
        if ifPathExist(path: downloadDataFilePath()) {
            var downloadedArr = [HTZDownloadModel]()
            for obj in downloadFileList() {
                if obj.state == HTZDownloadManagerState.finished {
                    downloadedArr.append(obj)
                }
            }
            return downloadedArr
        }
        return []
    }
    
    /// 遍历文件（未下载、下载中、暂停）
    ///
    /// - Returns:
    func toDownloadFileList() -> [HTZDownloadModel] {
        if ifPathExist(path: downloadDataFilePath()) {
            var toDownloadArr = [HTZDownloadModel]()
            for obj in downloadFileList() {
                if obj.state != HTZDownloadManagerState.finished {
                    toDownloadArr.append(obj)
                }
            }
            return toDownloadArr
        }
        return []
    }
    
    func writeToFileWithModelArr(modelArr: [HTZDownloadModel]) -> Void {
        NSKeyedArchiver.archiveRootObject(modelArr, toFile: downloadDataFilePath())
    }
    
    func ifExistDownloadModelWithID(ID: String) -> Bool {
        var exist = false
        if ifPathExist(path: downloadDataFilePath()) {
            let modelArr = NSKeyedUnarchiver.unarchiveObject(withFile: downloadDataFilePath()) as! [HTZDownloadModel]
            for obj in modelArr {
                if obj.fileID == ID {
                    exist = true
                    break
                }
            }
        }
        return exist
    }
    
    func fileSizeWithModel(model: HTZDownloadModel) -> CUnsignedLongLong {
        if ifPathExist(path: model.fileLocalPath) {
            do {
                return try FileManager.default.attributesOfItem(atPath: model.fileLocalPath)[FileAttributeKey.size] as! CUnsignedLongLong
            } catch {
                print(error)
            }
        }
        return 0
    }
    
}

// MARK: -
extension HTZDownloadManager {
    
    func convertFromByteNum(b: CUnsignedLongLong) -> String {
        if b == 0 {
            return ""
        }
        
        var strSize = ""
        if b/1024/1024/1024 >= 1 {
            strSize = String(format: "%.1fGB", b/1024/1024/1024)
        } else if b/1024/1024 >= 1 && b/1024/1024/1024 < 1  {
            strSize = String(format: "%.1fMB", b/1024/1024)
        } else if b/1024 >= 0 && b/1024/1024 < 1  {
            strSize = String(format: "%.1fKB", b/1024)
        }
        
        return strSize
    }
    
    // 保存数据模型
    private func saveDownloadModelArr(modelArr: [HTZDownloadModel]) -> Void {
        var downloadModelArr = [HTZDownloadModel]()
        if ifPathExist(path: downloadDataFilePath()) {
            for obj in modelArr {
                if !ifExistDownloadModelWithID(ID: obj.fileID!) {
                    downloadModelArr.append(obj)
                }
            }
        } else {
            downloadModelArr = modelArr
        }
        
        // 保存
        writeToFileWithModelArr(modelArr: downloadModelArr)
    }
    
    // 更新数据模型
    private func updateDownloadModel(model: HTZDownloadModel) -> Void {

        if ifPathExist(path: downloadDataFilePath()) {
            var downloadArr = downloadFileList()
            for (idx, obj) in downloadArr.enumerated() {
                if model.fileID == obj.fileID  {
                    if model.state == HTZDownloadManagerState.finished  {
                        let fileSize = fileSizeWithModel(model: model)
                        model.file_size = convertFromByteNum(b: fileSize)
                    }
                    downloadArr[idx] = model
                    break
                }
            }
            // 保存
            writeToFileWithModelArr(modelArr: downloadArr)
        }
    }
    
    // 删除数据模型
    private func deleteDownloadModelArr(modelArr: [HTZDownloadModel]) -> Void {
        
        if ifPathExist(path: downloadDataFilePath()) {
            var downloadArr = downloadFileList()
            
            for model in modelArr {
                for (idx, obj) in downloadArr.enumerated() {
                    if model.fileID == obj.fileID {
                        // 状态改变
                        model.state = HTZDownloadManagerState.none
                        updateDownloadModel(model: model)
                        
                        if delegate != nil && (delegate?.responds(to: Selector(("downloadChanged:::"))))! {
                            delegate?.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.none)
                        }
                        // 删除文件
                        if ifPathExist(path: obj.fileLocalPath) {
                            _ = removeDirWithPath(path: obj.fileLocalPath)
                        }
                        // 删除模型
                        downloadArr.remove(at: idx)
                        
                        // 重新保存
                        writeToFileWithModelArr(modelArr: downloadArr)
                    }
                }
            }
        }
    }
}

// MARK: - filepath
extension HTZDownloadManager {
    
    func downloadDataFilePath() -> String {
        
        return downloadDataDir().appending("downloadModel.plist")
    }
    
    func downloadDataDir() -> String {
        
        return kDocumentDirectory!.appending("download")
    }
    
    private func createFilePathWithPath(path: String) -> Bool {
        if !ifPathExist(path: path) {
            return FileManager.default.createFile(atPath: path, contents: nil)
        }
        return true
    }
    
    private func createDirWithPath(path: String) -> Bool {
        if !ifPathExist(path: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                return true
            } catch {
                print(error)
            }
        }
        return true
    }
    
    private func removeDirWithPath(path: String) -> Bool {
        if ifPathExist(path: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
                return true
            } catch {
                print(error)
            }
        }
        return true
    }
    
    private func ifPathExist(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
