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
    
    weak var delegate: HTZDownloadManagerDelegate?
    
    private var isCanBreakpoint: Bool = false
    
    private var currentDownloadFileID: String?
    
    private var dataTask: Request?
    
    private var downloadTask: DownloadRequest?
    
//    private let Provider = MoyaProvider<Target: TargetType>(endpointClosure: { (
//        _) -> Endpoint in
//        var endpoint = Endpoint(
//            url: url,
//            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
//            method: target.method,
//            task: task,
//            httpHeaderFields: target.headers
//        )
//        requestTimeOut = 30 // 每次请求都会调用endpointClosure 到这里设置超时时长 也可单独每个接口设置
//        switch target {
//        case .easyRequset:
//            return endpoint
//        case .register:
//            requestTimeOut = 5
//            return endpoint
//
//        default:
//            return endpoint
//        }
//    }, requestClosure: { (endpoint: Endpoint, dono: MoyaProvider.RequestResultClosure) in
//        do {
//            var request = try endpoint.urlRequest()
//            //设置请求时长
//            request.timeoutInterval = requestTimeOut
//            // 打印请求参数
//            if let requestData = request.httpBody {
//                print("\(request.url!)"+"\n"+"\(request.httpMethod ?? "")"+"发送参数"+"\(String(data: request.httpBody!, encoding: String.Encoding.utf8) ?? "")")
//            } else {
//                print("\(request.url!)"+"\(String(describing: request.httpMethod))")
//            }
//            done(.success(request))
//        } catch {
//            done(.failure(MoyaError.underlying(error, nil)))
//        }
//    }, plugins: [NetworkActivityPlugin(networkActivityClosure: { (changeType, targetType) in
//        print("networkPlugin \(changeType)")
//        //targetType 是当前请求的基本信息
//        switch(changeType){
//        case .began:
//            print("开始请求网络")
//
//        case .ended:
//            print("结束")
//        }
//    })], trackInflights: false
//    )
    
    /// 文件句柄对象
    private var fileHandle: FileHandle?
    
    
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
                
                updateDownloadModel(model: obj)
               
                if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                     delegate.downloadChanged(downloadManager: self, downloadModel: obj, state: HTZDownloadManagerState.waiting)
                }
            }
        }
        // 保存数据
        saveDownloadModelArr(modelArr: downloadArr)
        
        // 开始下载
        self.startDownloadTask()
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
            if let dataTask = self.dataTask, dataTask.task?.state == URLSessionTask.State.running {
                dataTask.suspend()
            } else if let downloadTask = self.downloadTask, downloadTask.task?.state == URLSessionTask.State.running {
                downloadTask.suspend()
            }
        }
        
        // 删除下载的文件
        self.deleteDownloadModelArr(modelArr: downloadArr)
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("removedDownloadArr::"))) {
            delegate.removedDownloadArr(downloadManager: self, downloadArr: downloadArr)
        }
        
        // 开启其他下载
        self.startDownloadTask()
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
            if let dataTask = self.dataTask, dataTask.task?.state == URLSessionTask.State.running {
                dataTask.suspend()
            } else if let downloadTask = self.downloadTask, downloadTask.task?.state == URLSessionTask.State.running {
                downloadTask.suspend()
            }
        }
        
        // 遍历数据，暂停当前下载
        for model in downloadFileList() {
            for obj in downloadArr {
                // 文件未下载完成，并且是需要暂停的文件
                if model.fileID == obj.fileID && model.state != HTZDownloadManagerState.finished {
                    // 状态改变
                    model.state = HTZDownloadManagerState.paused
                    updateDownloadModel(model: model)
                    
                    if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                        delegate.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.paused)
                    }
                }
            }
        }
        // 开始其他下载
        self.startDownloadTask()
    }
    
    // 继续下载 恢复下载，暂停后才能调用
    func resumeDownloadArr(downloadArr: [HTZDownloadModel]) -> Void {
        
        for model in downloadFileList() {
            for obj in downloadArr {
                // 文件未下载完成并且是需要恢复下载的文件
                if model.fileID == obj.fileID && model.state != HTZDownloadManagerState.finished {
                    // 状态改变
                    model.state = HTZDownloadManagerState.waiting
                    updateDownloadModel(model: model)
                    
                    if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                        delegate.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.waiting)
                    }
                }
            }
        }
        // 开始其他下载
        self.startDownloadTask()
    }
    
    /// 清除下载（包括下载中和等待下载的）
    func clearDownload() -> Void {
        if URLSessionTask.State.running == self.downloadTask?.task?.state {
            self.downloadTask?.suspend()
        }
        
        var toClearArr = [HTZDownloadModel]()
        for obj in downloadFileList() {
            if obj.state != HTZDownloadManagerState.finished {
                toClearArr.append(obj)
            }
        }
        self.deleteDownloadModelArr(modelArr: toClearArr)
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("removedDownloadArr::"))) {
            delegate.removedDownloadArr(downloadManager: self, downloadArr: toClearArr)
        }
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
    private func toDownloadFileList() -> [HTZDownloadModel] {
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
    
    private func writeToFileWithModelArr(modelArr: [HTZDownloadModel]) -> Void {
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

// MARK: - 下载
extension HTZDownloadManager {
    
    private func startDownloadTask() {
        // 正在下载
        if let downloadTask = self.downloadTask, downloadTask.task?.state == URLSessionTask.State.running , let dataTask = self.dataTask, dataTask.task?.state == URLSessionTask.State.running {
            // do nothing
        } else {
            var model: HTZDownloadModel?
            for obj in downloadFileList() {
                if obj.state == HTZDownloadManagerState.waiting {
                    model = obj
                    break
                }
            }
            if let model = model {
                self.currentDownloadFileID = model.fileID!
                model.state = HTZDownloadManagerState.downloading
                
                self.updateDownloadModel(model: model)
                
                // 下载中
                if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                    delegate.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.downloading)
                }
                
                if self.isCanBreakpoint {
                    startBreakpoint(model: model)
                } else {
                    startDownloadData(model: model)
                }
            } else { // 没有需要下载的文件
                self.currentDownloadFileID = nil
            }
        }
    }
    
    private func startDownloadData(model: HTZDownloadModel) {
        let urlStr = "http://htzshanghai.top/resources/audios/xingfuneixinchan/"
        let request = URLRequest(url: URL(string:urlStr + model.fileUrl!)!)
       
        self.downloadTask = download(request) { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
//            downloadDataFilePath()
            
            return (URL(string: model.fileLocalPath)!,DownloadRequest.DownloadOptions())
        }
        if let downloadTask = self.downloadTask {
            downloadTask.downloadProgress { (downloadProgress) in
                if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                    delegate.downloadProgress(downloadManager: self, downloadModel: model, totalSize: NSInteger(downloadProgress.totalUnitCount), downloadSize: NSInteger(downloadProgress.completedUnitCount), progress: Float(downloadProgress.completedUnitCount / downloadProgress.totalUnitCount))
                }
                print("共\(downloadProgress.totalUnitCount)\n当前下载\(downloadProgress.completedUnitCount)")
            }
            downloadTask.responseData { (response) in
                switch response.result {
                case .success(_): // 下载完成
                    model.state = HTZDownloadManagerState.finished
                    self.updateDownloadModel(model: model)
                    if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                        delegate.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.finished)
                    }
                    
                    if let delegate = self.delegate, delegate.responds(to: Selector(("removedDownloadArr::"))) {
                        delegate.removedDownloadArr(downloadManager: self, downloadArr: [model])
                    }
                    print(response)
                case .failure(_): // 下载失败
                     // 删除已下载的数据防止出错
                    self.deleteDownloadModelArr(modelArr: [model])
                    model.state = HTZDownloadManagerState.failed
                    self.updateDownloadModel(model: model)
                    
                    if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                        delegate.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.failed)
                    }
                    print(response)
                }
                
                // 停止下载
                if downloadTask.task?.state == URLSessionTask.State.running {
                    downloadTask.suspend()
                    self.downloadTask = nil
                }
                // 开始下载下一个
                self.startDownloadTask()
            }
        }
        if let downloadTask = self.downloadTask, downloadTask.task?.state == URLSessionTask.State.suspended {
            downloadTask.resume()
        }
    }
    
    private func startBreakpoint(model: HTZDownloadModel) {
        
//        let request = DataRequest.self
        
        
//        let request = NSMutableURLRequest(url: URL(string: model.fileUrl!)!)
//        let qu = Request(
        // 设置HTTP请求头中的Range
//        let range = "bytes=\(model.currentLength!)-"
//        request.setValue(range, forHTTPHeaderField: "Range")
//        download(resumingWith: Data, to: <#T##DownloadRequest.DownloadFileDestination?##DownloadRequest.DownloadFileDestination?##(URL, HTTPURLResponse) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions)#>)
//        self.dataTask =
        self.dataTask?.resume()
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
                        
                        if let delegate = self.delegate, delegate.responds(to: Selector(("downloadChanged:::"))) {
                            delegate.downloadChanged(downloadManager: self, downloadModel: model, state: HTZDownloadManagerState.none)
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
    
    func downloadDataFilePath(doc: String? = nil) -> String {
        var str = downloadDataDir()
        
        if let doc = doc {
           str = str.appending(doc)
        }
        return str.appending("downloadModel.plist")
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
