//
//  HTZVideoPlayCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/16.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZVideoPlayCellDelegate: NSObjectProtocol {
    
    func palyTheVideoAt(_ indexPath: IndexPath)
}

class HTZVideoPlayCell: UITableViewCell {
    
    var videoModel: HTZVideoModel? {
        didSet {
            self.headImageView.wb_setImage(urlStr: videoModel?.coverUrl ?? "")
            self.coverImageView.wb_setImage(urlStr: videoModel?.coverUrl ?? "")
//            do {
//                let data:Data = try Data(contentsOf: URL(string: videoModel?.coverUrl ?? "")!)
//                let image:UIImage = UIImage.init(data: data)!
//                let height = image.size.height
//                let width = image.size.width
//                weak var s = self
//                guard let weakSelf = s else { return }
//                var videoHeight: CGFloat = 120
//                if width < height {
//                    videoHeight = kScreenWidth * 0.5 * height / width
//                } else {
//                    videoHeight = kScreenWidth * 0.5 * width / height
//                }
//                print(videoHeight)
//                self.coverImageView.snp.updateConstraints { (make) in
//                    make.height.equalTo(videoHeight)
//                }
//                self.bgImgView.snp.updateConstraints { (make) in
//                    make.edges.equalTo(weakSelf.coverImageView)
//                }
//                self.effectView.snp.updateConstraints { (make) in
//                     make.edges.equalTo(weakSelf.bgImgView)
//                }
//                self.playButton.snp.updateConstraints { (make) in
//                    make.center.equalTo(weakSelf.coverImageView)
//                }
//                self.fullMaskView.snp.updateConstraints { (make) in
//                    make.edges.equalTo(weakSelf.contentView)
//                }
//
//            } catch {
                
//            }
            self.bgImgView.wb_setImage(urlStr: videoModel?.coverUrl ?? "")
            self.titleLabel.text = videoModel?.title
            self.contentLabel.text = videoModel?.content
        }
    }
    
    weak var delegate: HTZVideoPlayCellDelegate?
    
    private var indexPath: IndexPath?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.headImageView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.contentLabel)
        self.contentView.addSubview(self.bgImgView)
        self.bgImgView.addSubview(self.effectView)
        self.contentView.addSubview(self.coverImageView)
        self.coverImageView.addSubview(self.playButton)
        self.contentView.addSubview(self.fullMaskView)
        self.contentView.backgroundColor = .black
        self.selectionStyle = .none
        
        initConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initConstraint() {
        weak var s = self
        guard let weakSelf = s else { return }
        self.headImageView.snp.makeConstraints { (make) in
            make.top.left.equalTo(weakSelf.contentView).offset(kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(weakSelf.headImageView.snp.right).offset(kGlobelMargin)
            make.centerY.equalTo(weakSelf.headImageView)
        }
        
        self.contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(weakSelf.headImageView.snp.bottom).offset(kGlobelMargin)
            make.left.equalTo(weakSelf.headImageView)
            make.right.equalTo(weakSelf.contentView).offset(-kGlobelMargin)
        }
        
        self.coverImageView.snp.makeConstraints { (make) in
            make.top.equalTo(weakSelf.contentLabel.snp.bottom).offset(kGlobelMargin)
            make.left.right.equalTo(weakSelf.contentView)
            make.bottom.equalTo(weakSelf.contentView).offset(-kGlobelMargin)
            make.height.equalTo(kGlobelMargin * 40)
        }
        
        self.bgImgView.snp.makeConstraints { (make) in
            make.edges.equalTo(weakSelf.coverImageView)
        }
        
        self.effectView.snp.makeConstraints { (make) in
            make.edges.equalTo(weakSelf.bgImgView)
        }
        
        self.playButton.snp.makeConstraints { (make) in
            make.center.equalTo(weakSelf.coverImageView)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        self.fullMaskView.snp.makeConstraints { (make) in
            make.edges.equalTo(weakSelf.contentView)
        }
    }
    
    func setDelegate(delegate: HTZVideoPlayCellDelegate?, indexPath: IndexPath) {
        self.delegate = delegate
        self.indexPath = indexPath
    }
    
    func setNormalMode() {
        self.fullMaskView.isHidden = true
        self.titleLabel.textColor = .black
        self.contentLabel.textColor = .black
        self.contentView.backgroundColor = .white
    }
    
    func showMaskView() {
        UIView.animate(withDuration: 0.3) {
            self.fullMaskView.alpha = 1
        }
    }
    
    func hideMaskView() {
        UIView.animate(withDuration: 0.3) {
            self.fullMaskView.alpha = 0
        }
    }
    
    @objc private func playClickAction() {
        if let delegate = delegate, delegate.responds(to: Selector(("palyTheVideoAt:"))) {
            delegate.palyTheVideoAt(self.indexPath!)
        }
    }
    
    /// MARK: - 懒加载
    private lazy var playButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(playClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var fullMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var headImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.tag = 100
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var bgImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private lazy var effectView: UIView = {
        var view = UIView()
        if #available(iOS 8.0, *) {
            let effect = UIBlurEffect(style: UIBlurEffect.Style.dark)
            view = UIVisualEffectView(effect: effect)
        } else {
            let effectView = UIToolbar()
            effectView.barStyle = .blackTranslucent
            view = effectView
        }
        return view
    }()
}
