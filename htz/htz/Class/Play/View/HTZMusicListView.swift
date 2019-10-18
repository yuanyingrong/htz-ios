//
//  HTZMusicListView.swift
//  htz
//
//  Created by 袁应荣 on 2019/10/18.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZMusicListViewDeleagate: NSObjectProtocol {
    
    func listViewDidClickClose(_ listView: HTZMusicListView)
    
    func listViewDidSelect(_ listView: HTZMusicListView, _ selectRow: NSInteger)
}

class HTZMusicListView: BaseView {
    
    var dataArr: [HTZMusicModel] = []
    
    weak var delegate: HTZMusicListViewDeleagate?

    override func configSubviews() {
        super.configSubviews()
        
        self.addSubview(self.topView)
        self.addSubview(self.listTableView)
        self.addSubview(self.closeButton)
        
        self.topView.addSubview(self.topLine)
        self.topView.addSubview(self.loopButton)
        self.topView.addSubview(self.loopLabel)
        
        self.closeButton.addSubview(closeLine)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        weak var s = self
        guard let weakSelf = s else { return }
        
        self.topView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(weakSelf)
            make.height.equalTo(50)
        }
        
        self.closeButton.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(weakSelf)
            make.height.equalTo(50)
        }
        
        self.listTableView.snp.makeConstraints { (make) in
            make.left.right.equalTo(weakSelf)
            make.top.equalTo(weakSelf.topView.snp.bottom)
            make.bottom.equalTo(weakSelf.closeButton.snp.top)
        }
        
        self.topLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(weakSelf.topView)
            make.height.equalTo(0.5)
        }
        
        self.loopButton.snp.makeConstraints { (make) in
            make.left.equalTo(weakSelf.topView).offset(2 * kGlobelMargin)
            make.centerY.equalTo(weakSelf.topView)
        }
        
        self.loopLabel.snp.makeConstraints { (make) in
            make.left.equalTo(weakSelf.loopButton.snp.right).offset(0.5 * kGlobelMargin)
            make.centerY.equalTo(weakSelf.topView)
        }
        
        self.closeLine.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(weakSelf.closeButton)
            make.height.equalTo(0.5)
        }
    }
    
    
    private lazy var topView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var loopButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "loop_play"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "loop_play"), for: UIControl.State.highlighted)
        button.addTarget(self, action: #selector(loopButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var loopLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 17.0)
        return label
    }()
    
    private lazy var topLine: UIView = {
        let view = UIView()
        view.backgroundColor = .groupTableViewBackground
        return view
    }()
    
    private lazy var listTableView: UITableView = {
        let tableView = UITableView(frame: self.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.backgroundColor = UIColor.clear
        tableView.register(HTZMusicListCell.self, forCellReuseIdentifier: "HTZMusicListCellResuseID")
        return tableView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "loop_play"), for: UIControl.State.normal)
         button.addTarget(self, action: #selector(closeButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var closeLine: UIView = {
        let view = UIView()
        view.backgroundColor = .groupTableViewBackground
        return view
    }()

}

extension HTZMusicListView {
    
    @objc func loopButtonClickAction() {
        print("loopButtonClickAction")
        
    }
    
    @objc func closeButtonClickAction() {
           print("closeButtonClickAction")
        if let delegate = self.delegate, delegate.responds(to: Selector(("listViewDidClickClose:"))) {
            delegate.listViewDidClickClose(self)
        }
    }
    
    @objc func downloadButtonClickAction(cell: HTZMusicListCell) {
           print("downloadButtonClickAction")
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlView:didSliderTapped:"))) {
            let indexPath = self.listTableView.indexPath(for: cell)
            delegate.listViewDidSelect(self, indexPath?.row ?? 0)
        }
    }
    
}


// MARK: - UITableViewDataSource, UITableViewDelegate
extension HTZMusicListView: UITableViewDataSource, UITableViewDelegate {
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         
        return self.dataArr.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HTZMusicListCellResuseID", for: indexPath) as! HTZMusicListCell
        cell.musicModel = self.dataArr[indexPath.row]
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

class HTZMusicListCell: BaseTableViewCell {
    
    
    var musicModel: HTZMusicModel? {
            
            didSet {
                if let musicModel = musicModel {
                    
                    self.titleLabel.text = musicModel.song_name
                    
                    if musicModel.isDownload {
                        self.downloadButton.setImage(UIImage(named: "downloaded"), for: UIControl.State.normal)
                    } else {
                       self.downloadButton.setImage(UIImage(named: "download"), for: UIControl.State.normal)
                    }
                    
                }
            }
        }
    
    override func configSubView() {
        super.configSubView()
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(downloadButton)
        contentView.addSubview(bottomLine)
            
    }
        
    override func configConstraint() {
        super.configConstraint()
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(contentView).offset(0.5 * kGlobelMargin)
            make.left.equalTo(contentView).offset(kGlobelMargin)
        }
        
        downloadButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentView)
            make.right.equalTo(contentView).offset(-2 * kGlobelMargin)
        }
        
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(1)
            make.left.right.bottom.equalTo(contentView)
            }
    }
    
    private let titleLabel = UILabel(title: "1、第一讲", fontSize: 16, textColor: UIColor.darkText)
    
    private lazy var downloadButton: UIButton = {
        let downloadButton = UIButton(type: UIButton.ButtonType.custom)
        downloadButton.setImage(UIImage(named: "download"), for: UIControl.State.normal)
        downloadButton.addTarget(self, action: #selector(HTZMusicListView.downloadButtonClickAction(cell:)), for: UIControl.Event.touchUpInside)
        return downloadButton
    }()
    
    private lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.groupTableViewBackground
        return bottomLine
    }()
}
