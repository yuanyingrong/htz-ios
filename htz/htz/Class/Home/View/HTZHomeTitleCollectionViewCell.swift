//
//  HTZHomeTitleCollectionViewCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/8.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeTitleCollectionViewCell: UICollectionViewCell {
    
    var imageName: String? {
        didSet {
            if let imageName = imageName,imageName.hasPrefix("http") {
                imageView.wb_setImageWith(urlStr: imageName)
            } else {
                imageView.image = UIImage(named: imageName ?? "htz_no_title")
            }
            if let imageName = imageName, imageName.starts(with: "tests") {
                imageView.htz_setImage(fileId: imageName)
//                let imagePath = HTZDownloadManager.sharedInstance.downloadDataDir(doc: "images/")+imageName.replacingOccurrences(of: "/", with: "_")
//                if HTZDownloadManager.sharedInstance.ifPathExist(path: imagePath) {
//                    self.imageView.image = UIImage(contentsOfFile: imagePath)
//                } else {
//                    Provider.request(API.download(file_id: imageName, fileLocalPath: imagePath), progress: { (downloadProgressResponse) in
//                        guard let downloadProgress = downloadProgressResponse.progressObject else {return}
//
//                        print("共需下载\(downloadProgress.totalUnitCount)\n当前下载\(downloadProgress.completedUnitCount)")
//                    }) { (result) in
//
//                        switch result {
//                        case let .success(response):
//                            printLog(response)
//                            self.imageView.image = UIImage(contentsOfFile: imagePath)
//                            break
//                        case .failure(_):
//                            printLog(result)
//                            break
//                        }
//
//                    }
//                }
            }
        }
    }
    
    var title: String? {
        didSet {
            if let title = title {
                label.text = title
            }
            
        }
    }
    
    private let imageView = UIImageView()
    private let label = UILabel(text: "", font: 16, textColor: .darkText)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configSubViews()
        configConstraint()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configSubViews()
        configConstraint()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
     func configSubViews() {
        
        backgroundColor = .white
        addSubview(imageView)
        addSubview(label)
        
    }
    
     func configConstraint() {
        
        
        imageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.contentView)
        }
        
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom)
            make.centerX.equalTo(self.contentView)
            make.height.equalTo(24)
            make.bottom.equalTo(self.contentView).offset(-8)
        }
    }
}
