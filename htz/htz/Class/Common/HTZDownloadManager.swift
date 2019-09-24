//
//  HTZDownloadManager.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/5.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import Alamofire

let kDocumentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first

let kDownloadManager = HTZDownloadManager.sharedInstance

protocol HTZDownloadManagerDelegate: NSObjectProtocol {
    
    /// 下载状态改变
    ///
    /// - Parameters:
    ///   - downloadManager: <#downloadManager description#>
    ///   - downloadModel: <#downloadModel description#>
    ///   - state: <#state description#>
    func downloadChanged(_ downloadManager: HTZDownloadManager, downloadModel:HTZDownloadModel, state: HTZDownloadManagerState)
    
    /// 删除下载
    ///
    /// - Parameters:
    ///   - downloadManager: <#downloadManager description#>
    ///   - downloadArr: <#downloadArr description#>
    func removedDownloadArr(_ downloadManager: HTZDownloadManager, downloadArr: [HTZDownloadModel])
    
    /// 下载进度
    ///
    /// - Parameters:
    ///   - downloadManager: <#downloadManager description#>
    ///   - downloadModel: <#downloadModel description#>
    ///   - totalSize: <#totalSize description#>
    ///   - downloadSize: <#downloadSize description#>
    ///   - progress: <#progress description#>
    func downloadProgress(_ downloadManager: HTZDownloadManager, downloadModel:HTZDownloadModel, totalSize: NSInteger, downloadSize: NSInteger, progress: Float)
}

class HTZDownloadManager: NSObject {
    

    static let sharedInstance = HTZDownloadManager()
    
    weak var delegate: HTZDownloadManagerDelegate?
    
    private var isCanBreakpoint: Bool = false
    
    private var currentDownloadFileID: String?
    
    private var cancelled = false
    
    private var downloadRequest: DownloadRequest?
    
    /// 文件句柄对象
    private var fileHandle: FileHandle?
    
    private var resumeData: Data?
    
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
        for saveModel in downloadFileList() {
            for obj in saveModel.downloadFiles! {
                if fileID == obj.fileID && obj.state == HTZDownloadManagerState.finished {
                    isDownload = true
                }
            }
        }
        return isDownload
    }
    
    func checkDownloadState(fileID: String) -> HTZDownloadManagerState {
        var state = HTZDownloadManagerState.none
           for saveModel in downloadFileList() {
               for obj in saveModel.downloadFiles! {
                   if fileID == obj.fileID {
                    if obj.resumeData == nil {
                        obj.state = HTZDownloadManagerState.none
                    }
                    state = obj.state ?? HTZDownloadManagerState.none
                   }
               }
           }
           return state
       }
    
    // 根据id获取本地数据信息
    func modelWithID(fileID: String) -> HTZDownloadModel? {
        if checkDownloadWithID(fileID: fileID) {
            var model: HTZDownloadModel? = nil
            for saveModel in downloadFileList() {
                for obj in saveModel.downloadFiles! {
                    if fileID == obj.fileID {
                        model = obj
                    }
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
                
                updateDownloadModel(model: obj)
               
                if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                    delegate.downloadChanged(self, downloadModel: obj, state: HTZDownloadManagerState.waiting)
                }
            }
        }
        // 保存数据
        saveDownloadModelArr(modelArr: downloadArr)
        
        // 开始下载
        self.startdownloadRequest()
    }
    
    // 删除下载
    func removeDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        // 如果删除列表中有正在下载的文件，先暂停下载
        var exist = false
        for obj in downloadArr {
            if obj.fileID == self.currentDownloadFileID {
                exist = true
                break
            }
        }
        
        if exist {
            if let downloadRequest = self.downloadRequest, downloadRequest.task?.state == URLSessionTask.State.running {
                downloadRequest.suspend()
            }
        }
        
        // 删除下载的文件
        self.deleteDownloadModelArr(modelArr: downloadArr)
        
        if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.removedDownloadArr(_:downloadArr:))) {
            delegate.removedDownloadArr(self, downloadArr: downloadArr)
        }
        
        // 开启其他下载
        self.startdownloadRequest()
    }
    
    // 暂停下载
    func pausedDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        
        var exist = false
        for obj in downloadArr {
            if obj.fileID == self.currentDownloadFileID {
                exist = true
                break
            }
        }
        
        // 如果当前正在下载的是需要暂停的，找到并暂停当前下载
        if exist {
            if let downloadRequest = self.downloadRequest, downloadRequest.task?.state == URLSessionTask.State.running {
                
                downloadRequest.cancel(createResumeData: true)
                cancelled = true
                downloadRequest.suspend()
            }
        }
        
        // 遍历数据，暂停当前下载
        for saveModel in downloadFileList() {
            for model in saveModel.downloadFiles! {
                for obj in downloadArr {
                    // 文件未下载完成，并且是需要暂停的文件
                    if model.fileAlbumId == obj.fileAlbumId && model.fileID == obj.fileID && model.state != HTZDownloadManagerState.finished {
                        // 状态改变
                        model.state = HTZDownloadManagerState.paused
                        if let resumeData = self.resumeData {
                            model.resumeData = NSData(data: resumeData) as NSData?
                        }
                        
                        updateDownloadModel(model: model)
                        
                        if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                            delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.paused)
                        }
                    }
                }
            }
        }
        
        // 开始其他下载
        self.startdownloadRequest()
    }
    
    // 继续下载 恢复下载，暂停后才能调用
    func resumeDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        self.setCanBreakpoint(isCan: true)
        for saveModel in downloadFileList() {
            for model in saveModel.downloadFiles! {
                for obj in downloadArr {
                    // 文件未下载完成并且是需要恢复下载的文件
                    if model.fileAlbumId == obj.fileAlbumId && model.fileID == obj.fileID && model.state != HTZDownloadManagerState.finished {
                        // 状态改变
                        model.state = HTZDownloadManagerState.waiting
                        updateDownloadModel(model: model)
                        
                        if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                            delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.waiting)
                        }
                    }
                }
            }
        }
        
        // 开始其他下载
        self.startdownloadRequest()
    }
    
    /// 清除下载（包括下载中和等待下载的）
    func clearDownload() -> Void {
        if URLSessionTask.State.running == self.downloadRequest?.task?.state {
            self.downloadRequest?.suspend()
        }
        
        var toClearArr = [HTZDownloadModel]()
        for saveModel in downloadFileList() {
            for obj in saveModel.downloadFiles! {
                if obj.state != HTZDownloadManagerState.finished {
                    toClearArr.append(obj)
                }
            }
        }
        
        self.deleteDownloadModelArr(modelArr: toClearArr)
        
        if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.removedDownloadArr(_:downloadArr:))) {
            delegate.removedDownloadArr(self, downloadArr: toClearArr)
        }
    }
    
    /// 遍历文件（全部）
    func downloadFileList() -> [HTZSaveDataModel] {
        if ifPathExist(path: downloadDataFilePath()) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: downloadDataFilePath()) as! [HTZSaveDataModel]
        }
        return []
    }
    
    /// 遍历文件（已下载）
    func downloadedFileList() -> [HTZSaveDataModel] {
        if ifPathExist(path: downloadDataFilePath()) {
            var saveArr = [HTZSaveDataModel]()
            for saveModel in downloadFileList() {
                var downloadedArr = [HTZDownloadModel]()
                for obj in saveModel.downloadFiles! {
                    if obj.state == HTZDownloadManagerState.finished {
                        downloadedArr.append(obj)
                    }
                }
                if downloadedArr.count > 0 {
                    saveModel.downloadFiles = downloadedArr
                    saveArr.append(saveModel)
                }
            }
            return saveArr
        }
        return []
    }
    
    /// 遍历文件（未下载、下载中、暂停）
    ///
    /// - Returns:
    private func toDownloadFileList() -> [HTZDownloadModel] {
        if ifPathExist(path: downloadDataFilePath()) {
            var toDownloadArr = [HTZDownloadModel]()
            for saveModel in downloadFileList() {
                for obj in saveModel.downloadFiles! {
                    if obj.state != HTZDownloadManagerState.finished {
                        toDownloadArr.append(obj)
                    }
                }
            }
            
            return toDownloadArr
        }
        return []
    }
    
    private func writeToFileWithModelArr(modelArr: [HTZSaveDataModel]) -> Void {
        NSKeyedArchiver.archiveRootObject(modelArr, toFile: downloadDataFilePath())
    }
    
    private func ifExistDownloadModelWithID(ID: String) -> Bool {
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
    
    private func ifExistDownloadModel(downloadModel: HTZDownloadModel) -> Bool {
           var exist = false
           if ifPathExist(path: downloadDataFilePath()) {
               let saveArr = NSKeyedUnarchiver.unarchiveObject(withFile: downloadDataFilePath()) as! [HTZSaveDataModel]
               for model in saveArr {
                guard let downloadFiles = model.downloadFiles else { continue }
                for obj in downloadFiles {
                    if obj.fileID == downloadModel.fileID && obj.fileAlbumId == obj.fileAlbumId {
                        exist = true
                        break
                    }
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
    
    func fileSizeWithFileLocalPath(fileLocalPath: String) -> CUnsignedLongLong {
        if ifPathExist(path: fileLocalPath) {
            do {
                return try FileManager.default.attributesOfItem(atPath: fileLocalPath)[FileAttributeKey.size] as! CUnsignedLongLong
            } catch {
                print(error)
            }
        }
        return 0
    }
    
}

// MARK: - 下载
extension HTZDownloadManager {
    
    private func startdownloadRequest() {
        // 正在下载
        if let downloadRequest = self.downloadRequest, downloadRequest.task?.state == URLSessionTask.State.running {
            // do nothing
        } else {
            var model: HTZDownloadModel?
            for saveModel in downloadFileList() {
                for obj in saveModel.downloadFiles! {
                    if obj.state == HTZDownloadManagerState.waiting {
                        model = obj
                        break
                    }
                }
            }
            
            if let model = model {
                self.currentDownloadFileID = model.fileID!
                model.state = HTZDownloadManagerState.downloading
                
                self.updateDownloadModel(model: model)
                
                // 下载中
                if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                    delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.downloading)
                }
                if self.isCanBreakpoint && model.resumeData != nil {
                   self.startBreakpoint(model: model)
                } else {
                   self.startDownloadData(model: model)
                }
                
            } else { // 没有需要下载的文件
                self.currentDownloadFileID = nil
            }
        }
    }
    
    private func startDownloadData(model: HTZDownloadModel) {
        
        let request = URLRequest(url: URL(string: model.fileUrl!)!)
       
        self.downloadRequest = download(request) { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
//            downloadDataFilePath()
            
            return (URL(fileURLWithPath: model.fileLocalPath),DownloadRequest.DownloadOptions())
            }.downloadProgress(closure: { (downloadProgress) in
                if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadProgress(_:downloadModel:totalSize:downloadSize:progress:))) {
                    delegate.downloadProgress(self, downloadModel: model, totalSize: NSInteger(downloadProgress.totalUnitCount), downloadSize: NSInteger(downloadProgress.completedUnitCount), progress: Float(downloadProgress.completedUnitCount) / Float(downloadProgress.totalUnitCount))
                }
                 print("共需下载\(downloadProgress.totalUnitCount)\n当前下载\(downloadProgress.completedUnitCount)")
            }).responseData(completionHandler: { (response) in
                
                switch response.result {
                case .success(_): // 下载完成
                    model.state = HTZDownloadManagerState.finished
                    // 下载图片
                    
                    // 歌词
                    let lrcData = NSData(contentsOf: URL(string: model.fileLyric!)!)
                    lrcData?.write(toFile: model.fileLyricPath, atomically: true)
                    
                    self.updateDownloadModel(model: model)
                    if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                        delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.finished)
                    }
                    
                    if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.removedDownloadArr(_:downloadArr:))) {
                        delegate.removedDownloadArr(self, downloadArr: [model])
                    }
                    print(response)
                    break
                case .failure(_): // 下载失败
                    // 删除已下载的数据防止出错
                    if !self.cancelled {
                        self.deleteDownloadModelArr(modelArr: [model])
                         model.state = HTZDownloadManagerState.failed
                         self.updateDownloadModel(model: model)
                        
                         if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                             delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.failed)
                         }
                    } else {
                        model.state = HTZDownloadManagerState.paused
                        model.resumeData = response.resumeData as NSData?
                        self.updateDownloadModel(model: model)
                        if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                            delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.paused)
                        }
                    }
                    
                    print(response.error)
                }
                
                // 停止下载
                if self.downloadRequest?.task?.state == URLSessionTask.State.running {
                    self.downloadRequest?.suspend()
                    self.downloadRequest = nil
                }
                // 开始下载下一个
                self.startdownloadRequest()
            })
        
        if let downloadRequest = self.downloadRequest, downloadRequest.task?.state == URLSessionTask.State.suspended {
            downloadRequest.resume()
        }
    }
    
    private func startBreakpoint(model: HTZDownloadModel) {
        if model.resumeData != nil {
            self.resumeData = model.resumeData as Data?
        }
        if let resumeData = self.resumeData {
            self.downloadRequest = download(resumingWith: resumeData).downloadProgress(closure: { (downloadProgress) in
                if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadProgress(_:downloadModel:totalSize:downloadSize:progress:))) {
                    delegate.downloadProgress(self, downloadModel: model, totalSize: NSInteger(downloadProgress.totalUnitCount), downloadSize: NSInteger(downloadProgress.completedUnitCount), progress: Float(downloadProgress.completedUnitCount / downloadProgress.totalUnitCount))
                }
                print("续传共有\(downloadProgress.totalUnitCount)\n当前下载\(downloadProgress.completedUnitCount)")
            }).responseData(completionHandler: { (downloadResponse) in
                switch downloadResponse.result {
                case .success(_):  // 下载成功
                    model.state = HTZDownloadManagerState.finished
                    // 下载图片
                    
                    // 歌词
                    let lrcData = NSData(contentsOf: URL(string: model.fileLyric!)!)
                    lrcData?.write(toFile: model.fileLyricPath, atomically: true)
                    
                    self.updateDownloadModel(model: model)
                    
                    if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                        delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.finished)
                    }
                    
                    if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.removedDownloadArr(_:downloadArr:))) {
                        delegate.removedDownloadArr(self, downloadArr: [model])
                    }
                    break
                case .failure(_):  // 下载失败
                    if !self.cancelled {
                        self.deleteDownloadModelArr(modelArr: [model])
                         model.state = HTZDownloadManagerState.failed
                         self.updateDownloadModel(model: model)
                        
                         if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                             delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.failed)
                         }
                        print("断点方式下载失败\(String(describing: downloadResponse.error))")
                    } else {
                        model.state = HTZDownloadManagerState.paused
                        model.resumeData = downloadResponse.resumeData as NSData?
                        self.updateDownloadModel(model: model)
                        if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                            delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.paused)
                        }
                    }
                    break
                    
                }
                
                // 关闭fileHandl
//                self.fileHandle?.closeFile()
//                self.fileHandle = nil
                
                // 停止下载
                if self.downloadRequest?.task?.state == URLSessionTask.State.running {
                    self.downloadRequest?.suspend()
                    self.downloadRequest = nil
                }
                // 开始下载下一个
                self.startdownloadRequest()
            })
        }
        
        if self.downloadRequest?.task?.state == URLSessionTask.State.suspended {
            self.downloadRequest?.resume()
        }
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
        var saveArr = downloadFileList()
        var saveIndex: Int?
        var arr = [HTZDownloadModel]()
        for (idx, model) in saveArr.enumerated() {
            if modelArr.first!.fileAlbumId == model.albumID {
                arr = model.downloadFiles!
                saveIndex = idx
            }
        }
        if ifPathExist(path: downloadDataFilePath()) {
            for obj in modelArr {
                if !ifExistDownloadModel(downloadModel: obj) {
                    arr.append(obj)
                }
            }
            if let saveIndex = saveIndex {
                saveArr[saveIndex].downloadFiles = arr
            } else {
                let downloadModel = modelArr.first
                let model = HTZSaveDataModel()
                model.albumID = downloadModel?.fileAlbumId
                model.albumTitle = downloadModel?.fileAlbumName
                model.albumIcon = downloadModel?.fileCover
                model.downloadFiles = modelArr
                saveArr.append(model)
            }
        } else {
            let downloadModel = modelArr.first
            let model = HTZSaveDataModel()
            model.albumID = downloadModel?.fileAlbumId
            model.albumTitle = downloadModel?.fileAlbumName
            model.albumIcon = downloadModel?.fileCover
            model.downloadFiles = modelArr
            saveArr.append(model)
        }
        
        // 保存
        writeToFileWithModelArr(modelArr: saveArr)
    }
    
    // 更新数据模型
    private func updateDownloadModel(model: HTZDownloadModel) -> Void {

        if ifPathExist(path: downloadDataFilePath()) {
            let saveArr = downloadFileList()
            var saveIndex: Int?
            var downloadArr = [HTZDownloadModel]()
            for (idx, obj) in saveArr.enumerated() {
                if model.fileAlbumId == obj.albumID {
                    downloadArr = obj.downloadFiles!
                    saveIndex = idx
                }
            }
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
            if let saveIndex = saveIndex {
                saveArr[saveIndex].downloadFiles = downloadArr
            }
            
            // 保存
            writeToFileWithModelArr(modelArr: saveArr)
        }
    }
    
    // 删除数据模型
    func deleteDownloadModelArr(modelArr: [HTZDownloadModel]) -> Void {
        
        if ifPathExist(path: downloadDataFilePath()) {

            var saveArr = downloadFileList()
            for model in modelArr {
                for (saveIdx, saveModel) in saveArr.enumerated() {
                    guard model.fileAlbumId == saveModel.albumID else {
                        continue
                    }
                    var arr = saveModel.downloadFiles!
                    for (idx, obj) in arr.enumerated() {
                        if model.fileID == obj.fileID {
                            // 状态改变
                            model.state = HTZDownloadManagerState.none
                            updateDownloadModel(model: model)
                            
                            if let delegate = self.delegate, delegate.responds(to: #selector(HTZPlayViewController.downloadChanged(_:downloadModel:state:))) {
                                delegate.downloadChanged(self, downloadModel: model, state: HTZDownloadManagerState.none)
                            }
                            // 删除文件
                            if ifPathExist(path: obj.fileLocalPath) {
                                _ = removeDirWithPath(path: obj.fileLocalPath)
                                _ = removeDirWithPath(path: obj.fileLyricPath)
                                _ = removeDirWithPath(path: obj.fileImagePath)
                            }
                            // 删除模型
                            arr.remove(at: idx)
                            if arr.count > 0 {
                                saveArr[saveIdx].downloadFiles = arr
                            } else {
                                saveArr.remove(at: saveIdx)
                            }
                            // 重新保存
                            writeToFileWithModelArr(modelArr: saveArr)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - filepath
extension HTZDownloadManager {
    
    func downloadDataFilePath(doc: String? = nil) -> String {
        var str = downloadDataDir()
        
        if let doc = doc {
           str = str.appending(doc)
        }
        return str.appending("/downloadModel.plist")
    }
    
    func downloadDataDir(doc: String? = nil) -> String {
        var path = kDocumentDirectory!.appending("/download")
        
        if let doc = doc {
           path = path.appending("/\(doc)")
        }
        _ = createDirWithPath(path: path)
        return path
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
