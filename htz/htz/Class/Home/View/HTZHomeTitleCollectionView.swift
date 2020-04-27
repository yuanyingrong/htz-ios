//
//  HTZHomeTitleCollectionView
//  htz
//
//  Created by 袁应荣 on 2019/8/7.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZHomeTitleCollectionViewDelegate: NSObjectProtocol {
    
    // 点击更多按钮
    func moreButtonClickAtion()
    
    func collectionViewdidSelectItemAt(_ indexPath: IndexPath)
    
}
class HTZHomeTitleCollectionView: BaseView {
    
    var dataArr: [HTZSutraInfoModel?] = [] {
        
        didSet {
            collectionView.reloadData()
        }
    }
    
    var title: String? {
        didSet {
            leftLabel.text = title
        }
    }
    
    weak var delegate: HTZHomeTitleCollectionViewDelegate?

    override func configSubviews() {
        super.configSubviews()
        addSubview(titleView)
        titleView.addSubview(leftImageView)
        titleView.addSubview(leftLabel)
        titleView.addSubview(rightButton)
        addSubview(collectionView)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        titleView.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(self)
            make.height.equalTo(44)
        }
        
        leftImageView.snp.makeConstraints { (make) in
            make.left.equalTo(titleView).offset(16)
            make.centerY.equalTo(titleView)
        }
        
        leftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftImageView.snp.right).offset(4)
            make.centerY.equalTo(titleView)
        }
        
        rightButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleView)
            make.right.equalTo(titleView).offset(-16)
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(titleView.snp.bottom)
            make.left.right.bottom.equalTo(self)
        }
    }
    
    private lazy var titleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var leftImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var leftLabel: UILabel = {
        let label = UILabel(text: "专辑列表", font: 15, textColor: UIColor.darkGray)
        return label
    }()
    
    private lazy var rightButton: LeftTitleRightImageButton = {
        let button = LeftTitleRightImageButton()
        button.addTarget(self, action: #selector(rightButtonClickAction), for: .touchUpInside)
        button.setTitle("更多", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
        button.isHidden = true
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout();
        flowLayout.itemSize = CGSize(width: (UIScreen.main.bounds.size.width - 5 * 10) / 3, height: UIScreen.main.bounds.size.width/3)
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.minimumLineSpacing = 10
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HTZHomeTitleCollectionViewCell.self, forCellWithReuseIdentifier: "HTZHomeTitleCollectionViewCell")
        return collectionView
    }()

}

extension HTZHomeTitleCollectionView {
    @objc private func rightButtonClickAction() {
        if delegate != nil && (delegate?.responds(to: Selector(("moreButtonClickAtion"))))! {
            delegate?.moreButtonClickAtion()
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension HTZHomeTitleCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HTZHomeTitleCollectionViewCell", for: indexPath) as! HTZHomeTitleCollectionViewCell
        cell.imageName = dataArr[indexPath.row]?.cover
        cell.title = dataArr[indexPath.row]?.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if delegate != nil && (delegate?.responds(to: Selector(("collectionViewdidSelectItemAt:"))))! {
            delegate?.collectionViewdidSelectItemAt(indexPath)
        }
    }
    
}
