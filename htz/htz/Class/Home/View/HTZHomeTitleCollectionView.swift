//
//  HTZHomeTitleCollectionView
//  htz
//
//  Created by 袁应荣 on 2019/8/7.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

class HTZHomeTitleCollectionView: BaseView {

    private lazy var titleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var leftImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: ""))
        return imageView
    }()
    
    private lazy var leftLabel: UILabel = {
        let label = UILabel(text: "专辑列表", font: 15, textColor: UIColor.darkGray)
        return label
    }()
    
    private lazy var rightButton: TitleAndImageButton = {
        let button = TitleAndImageButton()
        button.addTarget(self, action: #selector(rightButtonClickAction), for: .touchUpInside)
        button.setTitle("更多", for: .normal)
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
        
        titleView.snp_makeConstraints { (make) in
            make.left.top.right.equalTo(self)
            make.height.equalTo(44)
        }
        
        leftImageView.snp_makeConstraints { (make) in
            make.left.equalTo(titleView).offset(16)
            make.centerY.equalTo(titleView)
        }
        
        leftLabel.snp_makeConstraints { (make) in
            make.left.equalTo(leftImageView.snp_right).offset(4)
            make.centerY.equalTo(titleView)
        }
        
        rightButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(titleView)
            make.right.equalTo(titleView).offset(-16)
        }
        
        collectionView.snp_makeConstraints { (make) in
            make.top.equalTo(titleView.snp_bottom)
            make.left.right.bottom.equalTo(self)
        }
    }
}

extension HTZHomeTitleCollectionView {
    @objc private func rightButtonClickAction() {
        
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension HTZHomeTitleCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HTZHomeTitleCollectionViewCell", for: indexPath) as! HTZHomeTitleCollectionViewCell
        cell.imageName = "https://goodreading.mobi/StudentApi/UserFiles/Banner/Student/Home/banner_tz.png"
        cell.title = "标题"
        return cell
    }
    
    
}
