//
//  UIImageView+extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/2.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import Kingfisher

extension UIImageView {
    
    /// 传imageName初始化一个imageView
    ///
    /// - Parameter imageName: 图片的名字
    convenience init(imageName: String) {
        self.init()
        self.image = UIImage(named: imageName)
    }
}

extension UIImageView {
    func wb_setImageWith(urlStr: String, placeHolder: String? = nil) {
        if let url = URL(string: urlStr) {
            
            if let placeHolder = placeHolder {
                kf.setImage(with: url, placeholder: UIImage(named: placeHolder))
            } else {
                kf.setImage(with: url)
            }
        }
    }
    
    func wb_setImage(urlStr: String, placeHolderImage: UIImage? = nil) {
        if let url = URL(string: urlStr) {
            
            if let placeHolderImage = placeHolderImage {
                kf.setImage(with: url, placeholder: placeHolderImage)
            } else {
                kf.setImage(with: url)
            }
        }
    }
    
    func htz_setImage(fileId: String, placeHolderImage: UIImage? = nil) {
        let imagePath = HTZDownloadManager.sharedInstance.downloadDataDir(doc: "images/")+fileId.replacingOccurrences(of: "/", with: "_")
        if HTZDownloadManager.sharedInstance.ifPathExist(path: imagePath) {
            self.image = UIImage(contentsOfFile: imagePath)
        } else {
            Provider.request(API.download(file_id: fileId, fileLocalPath: imagePath), progress: { (downloadProgressResponse) in
                guard let downloadProgress = downloadProgressResponse.progressObject else {return}
                
                print("共需下载\(downloadProgress.totalUnitCount)\n当前下载\(downloadProgress.completedUnitCount)")
            }) { (result) in
                
                switch result {
                case let .success(response):
                    printLog(response)
                    self.image = UIImage(contentsOfFile: imagePath)
                    break
                case .failure(_):
                    printLog(result)
                    break
                }
                
            }
        }
    }
    
}
