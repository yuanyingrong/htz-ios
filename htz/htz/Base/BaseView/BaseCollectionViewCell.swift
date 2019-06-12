//
//  BaseCollectionViewCell.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit
import SnapKit

class BaseCollectionViewCell: UICollectionViewCell {
    //MARK:-属性
    var collectionView : UICollectionView?
    
    lazy var layout : UICollectionViewFlowLayout = {[unowned self] in
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
        }()
    
    
    override func awakeFromNib() {
        super .awakeFromNib()
        configInterface()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configInterface()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configInterface() {
        configSubViews()
        configConstraint()
        configData()
    }
    
    //配置子view
    func configSubViews() {
        
        collectionView = UICollectionView(frame:CGRect.zero,collectionViewLayout: self.layout)
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.isScrollEnabled = false
        collectionView?.backgroundColor = UIColor.clear
        self .addSubview(collectionView!)
    }
    //配置约束
    func configConstraint() {
        collectionView?.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    //配置数据
    func configData() {
        
    }
    
    //让子类去实现
    func configCellData(_ data: AnyObject) -> Void {
        
    }
    
    
}

//让子类去实现
extension BaseCollectionViewCell : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = UICollectionReusableView()
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = UICollectionViewCell()
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}


extension BaseCollectionViewCell : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

extension BaseCollectionViewCell : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.zero
    }
}

extension BaseCollectionViewCell {
    class func reuseIdentifier() -> String {
        return NSStringFromClass(self).components(separatedBy:".").last!
    }
    
    class func nib() -> UINib {
        let xibName = NSStringFromClass(self).components(separatedBy: ".").last!
        return UINib (nibName: xibName, bundle:nil)
    }
    
    class func clazz() -> AnyClass {
        let clazz = NSStringFromClass(self).components(separatedBy:".").last!
        
        return NSClassFromString(clazz)!;
    }
    
    
}
