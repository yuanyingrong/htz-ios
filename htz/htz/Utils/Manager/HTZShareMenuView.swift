//
//  HTZShareMenuView.swift
//  htz
//
//  Created by 袁应荣 on 2020/4/12.
//  Copyright © 2020 袁应荣. All rights reserved.
//

import UIKit

class HTZShareMenuView: UIView {
    
    var platformTemps: [JSHAREPlatform] = [.wechatSession,.wechatTimeLine]
    
    var shareImageURL : AnyObject?
    var shareContent : String?
    var shareTitle : String?
    var shareUrl : String?
    fileprivate var titles: [String]  = []
    fileprivate var images: [String]  = []
    let shareParames = NSMutableDictionary()//分享字典
    
    private var _thumbImage: AnyObject!
    var thumbImage: AnyObject {
        get {
            return _thumbImage
        }
        set {
            
            if newValue.isKind(of: NSString.self) {
                _thumbImage = UIImage(named: newValue as! String)!
            } else if newValue.isKind(of: NSData.self) {
                _thumbImage = UIImage(data: newValue as! Data)!
            } else if newValue.isKind(of: UIImage.self) {
                _thumbImage = newValue
            }  else {
//                _thumbImage = kAppIcon
            }
            
        }
    }
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let array = checkSupportApplication()
        titles = ["微信", "朋友圈"]
        images = array[0] as! [String]
        let tags:[NSInteger] = array[1] as! [NSInteger]
        self.setUpUI()
        self.layout()
        self.addTap()
    }
    
    static func showInView(view: UIView, shareImageURL: AnyObject, shareContent: String, shareTitle: String, shareUrl: String) -> HTZShareMenuView? {
        let shareview = HTZShareMenuView(frame: view.bounds)
        //        shareview.createImageAndTitle(type: type)
        //        shareview.type = type
        shareview.shareImageURL = shareImageURL
        shareview.shareContent = shareContent
        shareview.shareTitle = shareTitle
        shareview.shareUrl = shareUrl
        //print("创建\(shareview)")
        view.addSubview(shareview)
        return shareview
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("销毁")
    }
    
    
    @objc func cancleAction() {
        menuHidden()
    }
    
     func menuHidden() {
        UIView.animate(withDuration: 0.2, animations: {
//            self.whiteBackView.frame = CGRect(x: 0, y: kScreenHeight, width: kScreenWidth, height: self.whiteHeight)
            self.alpha = 0
        }) { (finished) in
            self.removeFromSuperview()
        }
    }

    private func config() {
        platformTemps = [.wechatTimeLine, .wechatSession, .wechatFavourite];
    }
    
    private func customSharePlatform(paltfrom: JSHAREPlatform) {
        let shareMessage = JSHAREMessage()
        shareMessage.title = shareTitle
        shareMessage.url = shareUrl
        shareMessage.text = shareContent
        shareMessage.image = UIImage(named: "wechat")?.jpegData(compressionQuality: 0.9)
//        shareMessage.image
        shareMessage.platform = paltfrom
        shareMessage.mediaType = .link
        JSHAREService.share(shareMessage) { (state, error) in
            printLog("分享回调")
            self.menuHidden()
        }
        
    }
    
    func zip(scaleImage: UIImage, kb: NSInteger) -> Data {
        let kb = kb * 1024
        var compression: CGFloat = 0.9
        let maxCompression: CGFloat = 0.1
        
        var imageData = scaleImage.jpegData(compressionQuality: compression)
        while imageData!.count > kb && compression > maxCompression {
            compression -= 0.1
            // UIImage转换为NSData 第二个参数为压缩倍数
            imageData = scaleImage.jpegData(compressionQuality: compression)
        }
        return imageData!
    }
    
    @objc func cancelButtonClickAction() {
        menuHidden()
    }
    
    
    //更新约束override继承父类加每次add
    override func layoutSubviews() {
        super.layoutSubviews()
        //移动动画
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.25)
        shareView.center = CGPoint(x: kScreenWidth/2.0, y: kScreenHeight - 250/2.0)
        UIView.setAnimationCurve(UIView.AnimationCurve.easeOut) //设置动画相对速度
        UIView.commitAnimations()
    }
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.addTarget(self, action: #selector(cancelButtonClickAction), for: .touchUpInside)
        button.setTitle("取消分享", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {[weak self ] in
        let flowLayout = UICollectionViewFlowLayout();
        flowLayout.itemSize = CGSize(width:(kScreenWidth-61) / 5.0, height: 80)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 5
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HTZShareCollectionViewCell.self, forCellWithReuseIdentifier: "shareCollectionViewCellReuseID")
        return collectionView
    }()
    
    fileprivate lazy var shareView: UIView = {[weak self] in
        let view = UIView()
        view.backgroundColor = UIColor.white
//        view.alpha = 0.8
        //view.backgroundColor = UIColor.cyan
        return view
        }()
    
    fileprivate lazy var lineOne : UIImageView = {[weak self] in
        let line = UIImageView()
        line.image = UIImage.init(named: "line_left")
        return line
        }()
    
    fileprivate lazy var lineTwo : UIImageView = {[weak self] in
        let line = UIImageView()
        line.image = UIImage.init(named: "line_right")
        return line
        }()
    fileprivate lazy var titleLabel : UILabel = {[weak self] in
        let label = UILabel(title: "请选择分享平台", fontSize: 16, textColor: UIColor.black, alignMent: .center, numOfLines: 0)
        return label
        }()
}

extension HTZShareMenuView  {
    fileprivate func setUpUI() {
        addSubview(shareView)
        shareView.addSubview(lineOne)
        shareView.addSubview(lineTwo)
        shareView.addSubview(titleLabel)
        shareView.addSubview(collectionView)
        shareView.addSubview(cancelButton)
    }
    
}

extension HTZShareMenuView {
    fileprivate func layout() {
        
        shareView.snp.updateConstraints { (make) in
            make.top.equalTo(self.snp.bottom).offset(0)
            make.left.equalTo(self).offset(0)
            make.right.equalTo(self).offset(0)
            make.height.equalTo(250)
        }

        collectionView.snp.updateConstraints { (make) in
            make.edges.equalTo(shareView).inset(UIEdgeInsets(top: 40, left: 0, bottom: 64, right: 0))//上左下右
        }
        
        titleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(shareView).offset(15)
            make.centerX.equalTo(self)
        }
        
        lineOne.snp.updateConstraints { (make) in
            make.top.equalTo(shareView).offset(20)
            make.right.equalTo(titleLabel.snp.left).offset(-20)
            make.size.equalTo(CGSize(width: kScreenWidth * 0.42, height: 0.5))
        }
        
        lineTwo.snp.updateConstraints { (make) in
            make.top.equalTo(shareView).offset(20)
            make.left.equalTo(titleLabel.snp.right).offset(20)
            make.size.equalTo(CGSize(width: kScreenWidth * 0.42, height: 0.5))
        }
        
        cancelButton.snp.updateConstraints { (make) in
            make.left.bottom.right.equalTo((shareView))
            make.height.equalTo(54)
        }
    }
}

extension HTZShareMenuView {
    fileprivate func addTap() {
        //创建点手势
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(showShareView))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    @objc fileprivate func showShareView(){
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.init(rawValue: 7), animations: {
            self.shareView.frame = CGRect(x: 0, y: kScreenHeight, width: kScreenWidth, height: 230)
        }) { (finished) in
            self.removeFromSuperview()
        }
    }
}


// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension HTZShareMenuView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shareCollectionViewCellReuseID", for: indexPath) as! HTZShareCollectionViewCell
        // cell.backgroundColor = UIColor.lightGray
         cell.title.text = titles[indexPath.row]
         cell.image.image = UIImage.init(named: images[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
//        if delegate != nil && (delegate?.responds(to: Selector(("collectionViewdidSelectItemAt:"))))! {
//            delegate?.collectionViewdidSelectItemAt(indexPath)
//        }
        print("点击第\(indexPath.row)个分享")
        print("\(String(describing: shareImageURL)),\(String(describing: shareContent)),\(String(describing: shareTitle)),\(String(describing: shareUrl))")
//        share(types: indexPath.row,type:type!)
        switch indexPath.row {
        case 0: // 微信
            customSharePlatform(paltfrom: .wechatSession)
            break
        case 1: // 微信朋友圈
            customSharePlatform(paltfrom: .wechatTimeLine)
            break
        case 2: // 微信收藏
            customSharePlatform(paltfrom: .wechatFavourite)
            break
        default:
            break
        }
    }
}

//tap
extension HTZShareMenuView : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: self.shareView)
//        print("touch=\(touch)")
//        print("touch.view=\(touch.view)")
//        print("touchPoint=\(touchPoint)")
        if self.shareView.bounds.contains(touchPoint) {
            return false
        }
        return true
    }
}

extension HTZShareMenuView {
    /// 第三方安装检测
    private func checkSupportApplication() -> [[Any]] {
        var images:[String] = []
        var tags:[NSInteger] = []
        for type in platformTemps {
            switch type {
            case .wechatSession:
                if JSHAREService.isWeChatInstalled() {
                    images.append("wechat")
                    tags.append(0)
                }
                break
            case .wechatTimeLine:
                if JSHAREService.isWeChatInstalled() {
                    images.append("friends")
                    tags.append(2)
                }
                break
            case .wechatFavourite:
                if JSHAREService.isWeChatInstalled() {
                    images.append("分享微信收藏")
                    tags.append(3)
                }
                break
            default:
                break
            }
        }
        return [images, tags]
    }
}

class HTZShareCollectionViewCell: UICollectionViewCell {
    lazy var  title = UILabel()
    lazy var image = UIImageView()
    override init(frame:CGRect){
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        title.font = UIFont.systemFont(ofSize: 11)
        title.textColor = UIColor.white
        contentView.addSubview(title)
        contentView.addSubview(image)
        //
        image.snp.updateConstraints { (make) in
            make.top.equalTo(self.contentView).offset(0)
            make.centerX.equalTo(self.contentView).offset(0)
            make.height.equalTo(50)
            make.width.equalTo(50)
        }
        title.snp.updateConstraints { (make) in
            make.top.equalTo(self.image.snp.bottom).offset(10)
            make.centerX.equalTo(self.contentView).offset(0)
        }
    }
    
}
