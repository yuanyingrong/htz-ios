//
//  HTZProfileFunctionView.swift
//  htz
//
//  Created by 袁应荣 on 2019/8/27.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZProfileFunctionViewDelegate: NSObjectProtocol {
    
    /// index: 1历史 2订阅 3收藏
    func functionTapAction(_ index:NSInteger)
}

class HTZProfileFunctionView: BaseView {
    
    weak var delegate:HTZProfileFunctionViewDelegate?
    
    private lazy var historyView: HTZLabelView = {
        let historyView = HTZLabelView()
        historyView.backgroundColor = UIColor.clear
        historyView.title = "历史"
        return historyView
    }()
    
    private lazy var verticalLine1: UIView = {
        let verticalLine1 = UIView()
        verticalLine1.backgroundColor = UIColor.groupTableViewBackground
        return verticalLine1
    }()
    
    private lazy var subscribeView: HTZLabelView = {
        let subscribeView = HTZLabelView()
        subscribeView.backgroundColor = UIColor.clear
        subscribeView.title = "订阅"
        return subscribeView
    }()
    
    private lazy var verticalLine2: UIView = {
        let verticalLine2 = UIView()
        verticalLine2.backgroundColor = UIColor.groupTableViewBackground
        return verticalLine2
    }()
    
    private lazy var collectView: HTZLabelView = {
        let collectView = HTZLabelView()
        collectView.backgroundColor = UIColor.clear
        collectView.title = "收藏"
        return collectView
    }()

    override func configSubviews() {
        super.configSubviews()
        
        backgroundColor = UIColor.darkGray
        
        addSubview(historyView)
        addSubview(verticalLine1)
        addSubview(subscribeView)
        addSubview(verticalLine2)
        addSubview(collectView)
        
        let tapHistoryGesture = UITapGestureRecognizer(target: self, action: #selector(tapHistoryGestureAction))
        historyView.addGestureRecognizer(tapHistoryGesture)
        let tapSubscribeGesture = UITapGestureRecognizer(target: self, action: #selector(tapSubscribeGestureAction))
        subscribeView.addGestureRecognizer(tapSubscribeGesture)
        let tapCollectGesture = UITapGestureRecognizer(target: self, action: #selector(tapCollectGestureAction))
        collectView.addGestureRecognizer(tapCollectGesture)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        historyView.snp_makeConstraints { (make) in
            make.left.top.bottom.equalTo(self)
            make.width.equalTo(kScreenWidth * 0.33)
        }
        
        verticalLine1.snp_makeConstraints { (make) in
            make.left.equalTo(historyView.snp_right)
            make.top.equalTo(self).offset(16)
            make.bottom.equalTo(self).offset(-16)
            make.width.equalTo(1)
        }
        
        subscribeView.snp_makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.centerX.equalTo(self)
            make.width.equalTo(kScreenWidth * 0.33)
        }
        
        verticalLine2.snp_makeConstraints { (make) in
            make.left.equalTo(subscribeView.snp_right)
            make.top.bottom.width.equalTo(verticalLine1)
        }
        
        collectView.snp_makeConstraints { (make) in
            make.left.equalTo(verticalLine2.snp_right)
            make.top.right.bottom.equalTo(self)
        }
    }

}
// MARK: 手势点击事件
extension HTZProfileFunctionView {
    
    @objc func tapHistoryGestureAction() {

        if delegate != nil && (delegate?.responds(to: Selector(("functionTapAction:"))))! {
            delegate?.functionTapAction(1)
        }
    }
    
    @objc private func tapSubscribeGestureAction() {
        if delegate != nil && (delegate?.responds(to: Selector(("functionTapAction:"))))! {
            delegate?.functionTapAction(2)
        }
    }
    
    @objc private func tapCollectGestureAction() {
        if delegate != nil && (delegate?.responds(to: Selector(("functionTapAction:"))))! {
            delegate?.functionTapAction(3)
        }
    }
}
