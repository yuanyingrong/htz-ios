//
//  HTZMusicControlView.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/10.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZMusicControlViewDelegate: NSObjectProtocol {
    
    // 按钮
    func controlViewDidClickLove(_ controlView: HTZMusicControlView)
    func controlViewDidClickDownload(_ controlView: HTZMusicControlView)
    
    func controlViewDidClickLoop(_ controlView: HTZMusicControlView)
    func controlViewDidClickPlay(_ controlView: HTZMusicControlView)
    func controlViewDidClickPrev(_ controlView: HTZMusicControlView)
    func controlViewDidClickNext(_ controlView: HTZMusicControlView)
    func controlViewDidClickList(_ controlView: HTZMusicControlView)
    
    // 滑杆滑动及点击
    func controlView(_ controlView: HTZMusicControlView, didSliderTouchBegan value: CGFloat)
    func controlView(_ controlView: HTZMusicControlView, didSliderTouchEnded value: CGFloat)
    func controlView(_ controlView: HTZMusicControlView, didSliderValueChange value: CGFloat)
    func controlView(_ controlView: HTZMusicControlView, didSliderTapped value: CGFloat)
}
class HTZMusicControlView: BaseView {
    
    weak var delegate: HTZMusicControlViewDelegate?
    
    var style: HTZPlayerPlayStyle? {
        didSet {
            switch style {
            case .loop?:
                self.loopButton.setImage(UIImage(named: "loop_play"), for: UIControl.State.normal)
                self.loopButton.setImage(UIImage(named: "loop_play"), for: UIControl.State.highlighted)
                break
            case .random?:
                self.loopButton.setImage(UIImage(named: "sequential_play"), for: UIControl.State.normal)
                self.loopButton.setImage(UIImage(named: "sequential_play"), for: UIControl.State.highlighted)
                break
            case .one?:
                self.loopButton.setImage(UIImage(named: "single_play"), for: UIControl.State.normal)
                self.loopButton.setImage(UIImage(named: "single_play"), for: UIControl.State.highlighted)
                break
                
            case .none: break
                
            }
        }
    }
    
    
    lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    lazy var slider: HTZSliderView = {
        let slider = HTZSliderView()
        slider.setBackgroundImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.normal)
        slider.setBackgroundImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.selected)
        slider.setBackgroundImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.highlighted)
        
        slider.setThumbImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.normal)
        slider.setThumbImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.selected)
        slider.setThumbImage(image: UIImage(named: "read_classics_icon_normal"), state: UIControl.State.highlighted)
        
        slider.maximumTrackImage = UIImage(named: "read_classics_icon_normal")
        slider.minimumTrackImage = UIImage(named: "read_classics_icon_normal")
        slider.bufferTrackImage = UIImage(named: "read_classics_icon_normal")
        
        slider.delegate = self
        slider.sliderHeight = 2
        
        return slider
    }()
    
    var currentTime: String? {
        didSet {
            self.currentLabel.text = currentTime
        }
    }
    var totalTime: String?{
        didSet {
            self.totalLabel.text = totalTime
        }
    }
    var progress: CGFloat?{
        didSet {
            self.slider.value = progress!
            self.slider.layoutIfNeeded()
        }
    }
    var bufferProgress: CGFloat?{
        didSet {
            self.slider.bufferValue = bufferProgress!
            self.slider.layoutIfNeeded()
        }
    }
    
    var is_love: Bool? {
        didSet {
            if let is_love = is_love, is_love {
                    self.loveButton.setImage(UIImage(named: "liked"), for: UIControl.State.normal)
                    self.loveButton.setImage(UIImage(named: "liked"), for: UIControl.State.highlighted)
                } else {
                    self.loveButton.setImage(UIImage(named: "like"), for: UIControl.State.normal)
                    
            }
            
        }
    }
    var is_download: Bool? {
        didSet {
            if let is_download = is_download, is_download {
                self.downloadButton.setImage(UIImage(named: "downloaded"), for: UIControl.State.normal)
                self.downloadButton.setImage(UIImage(named: "downloaded"), for: UIControl.State.highlighted)
            } else {
                self.downloadButton.setImage(UIImage(named: "download"), for: UIControl.State.normal)
                self.downloadButton.setImage(UIImage(named: "download"), for: UIControl.State.highlighted)
            }
        }
    }
    
    func initialData() {
        self.progress = 0
        self.bufferProgress = 0
        self.currentTime = "00:00"
        self.totalTime = "00:00"
    }
    
    func showLoadingAnim() {
        if let isLoading = self.isLoading, isLoading { return }
        self.isLoading = true
        self.slider.showLoading()
    }
    
    func hideLoadingAnim() {
        guard let isLoading = self.isLoading, isLoading else { return }
        self.isLoading = false
        self.slider.hideLoading()
    }
    
    func setupPlayButton() {
        self.playButton.setImage(UIImage(named: "stop"), for: UIControl.State.normal)
        self.playButton.setImage(UIImage(named: "stop"), for: UIControl.State.highlighted)
    }
    
    func setupPauseButton() {
        self.playButton.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        self.playButton.setImage(UIImage(named: "play"), for: UIControl.State.highlighted)
    }
    
    private lazy var loveButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "love"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "love_prs"), for: UIControl.State.highlighted)
        button.addTarget(self, action: #selector(loveButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()

    private lazy var downloadButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "download"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "download_prs"), for: UIControl.State.highlighted)
        button.addTarget(self, action: #selector(downloadButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var loopButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "loop_play"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "loop_play"), for: UIControl.State.highlighted)
        button.addTarget(self, action: #selector(loopButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()
    private lazy var playButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "play"), for: UIControl.State.normal)
        button.setImage(UIImage(named: "stop"), for: UIControl.State.highlighted)
        button.addTarget(self, action: #selector(playOrPauseMusic), for: UIControl.Event.touchUpInside)
        return button
    }()
   
    private lazy var previousButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "pre"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(previousMusic), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "next"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(nextMusic), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    private lazy var listButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "item_list"), for: UIControl.State.normal)
        button.addTarget(self, action: #selector(listButtonClickAction), for: UIControl.Event.touchUpInside)
        return button
    }()

    private lazy var sliderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private lazy var currentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()
    
    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()
    
    private var isLoading: Bool?
    
    override func configSubviews() {
        super.configSubviews()
        
        self.backgroundColor = UIColor.clear
        
        // 顶部
        self.addSubview(self.topView)
        self.topView.addSubview(self.loveButton)
        self.topView.addSubview(self.downloadButton)
        
        // 滑杆
        self.addSubview(self.sliderView)
        self.sliderView.addSubview(self.currentLabel)
        self.sliderView.addSubview(self.slider)
        self.sliderView.addSubview(self.totalLabel)
        
        // 底部
        
        self.addSubview(self.listButton)
        self.addSubview(self.playButton)
        self.addSubview(self.previousButton)
        self.addSubview(self.nextButton)
    }
    
    override func configConstraint() {
        super.configConstraint()
        
        self.topView.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(self)
            make.height.equalTo(50)
        }
        
        self.loveButton.snp.makeConstraints { (make) in
            make.right.equalTo(self.topView.centerX).offset(-2 * kGlobelMargin)
            make.centerY.equalTo(self.topView)
            make.width.equalTo(50)
        }
        
        self.downloadButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.topView.centerX).offset(2 * kGlobelMargin)
            make.centerY.equalTo(self.topView)
            make.width.equalTo(50)
        }
        
        self.sliderView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.top.equalTo(self.topView.snp.bottom)
            make.height.equalTo(30)
        }
        
        self.slider.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self.sliderView)
            make.left.equalTo(self.sliderView).offset(60)
            make.right.equalTo(self.sliderView).offset(-60)
        }
        
        self.currentLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.slider.snp.left).offset(-30)
            make.centerY.equalTo(self.sliderView)
        }
        
        self.totalLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.slider.snp.right).offset(30)
            make.centerY.equalTo(self.sliderView)
        }
        
        self.playButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-2 * kGlobelMargin)
            } else {
                make.bottom.equalTo(self).offset(-2 * kGlobelMargin)
            }
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        self.previousButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.right.equalTo(playButton.snp.left).offset(-4 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        self.nextButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.left.equalTo(playButton.snp.right).offset(4 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        self.listButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.right.equalTo(previousButton.snp.left).offset(-4 * kGlobelMargin)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
//        self.listButton.snp.makeConstraints { (make) in
//            make.centerY.equalTo(playButton)
//            make.left.equalTo(nextButton.snp.right).offset(4 * kGlobelMargin)
//            make.size.equalTo(CGSize(width: 40, height: 40))
//        }
    }
}

// MARK: - 按钮点击事件
extension HTZMusicControlView {
    
    @objc private func loveButtonClickAction() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickLove:"))) {
            delegate.controlViewDidClickLove(self)
        }
        
    }
    
    @objc private func downloadButtonClickAction() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickDownload:"))) {
            delegate.controlViewDidClickDownload(self)
        }
    }
    
    @objc private func loopButtonClickAction() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickLoop:"))) {
            delegate.controlViewDidClickLoop(self)
        }
    }
    
    // 播放或暂停按钮点击事件
    @objc private func playOrPauseMusic() {
        self.playButton.isSelected = !playButton.isSelected
        if self.playButton.isSelected {
            self.setupPlayButton()
        } else {
            self.setupPauseButton()
        }
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickPlay:"))) {
            delegate.controlViewDidClickPlay(self)
        }
    }
    
    // 上一曲按钮点击事件
    @objc private func previousMusic() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickPrev:"))) {
            delegate.controlViewDidClickPrev(self)
        }
    }
    
    // 下一曲按钮点击事件
    @objc private func nextMusic() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickNext:"))) {
            delegate.controlViewDidClickNext(self)
        }
    }
    
    @objc private func listButtonClickAction() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlViewDidClickList:"))) {
            delegate.controlViewDidClickList(self)
        }
    }
    
}

// MARK: - HTZSliderViewDelegate
extension HTZMusicControlView: HTZSliderViewDelegate {
    @objc internal func sliderTouchBegin(_ value: CGFloat) {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlView:didSliderTouchBegan:"))) {
            delegate.controlView(self
                , didSliderTouchBegan: value)
        }
    }
    
    @objc internal func sliderValueChanged(_ value: CGFloat) {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlView:didSliderValueChange:"))) {
            delegate.controlView(self
                , didSliderValueChange: value)
        }
    }
    
    @objc internal func sliderTouchEnded(_ value: CGFloat) {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlView:didSliderTouchEnded:"))) {
            delegate.controlView(self
                , didSliderTouchEnded: value)
        }
    }
    
    @objc internal func sliderTapped(_ value: CGFloat) {
        if let delegate = self.delegate, delegate.responds(to: Selector(("controlView:didSliderTapped:"))) {
            delegate.controlView(self
                , didSliderTapped: value)
        }
    }
    
    
}
