//
//  HTZSliderView.swift
//  htz
//
//  Created by 袁应荣 on 2019/9/10.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import UIKit

protocol HTZSliderViewDelegate: NSObjectProtocol {
    
    func sliderTouchBegin(_ value: CGFloat)
    
    func sliderValueChanged(_ value: CGFloat)
    
    func sliderTouchEnded(_ value: CGFloat)
    
    func sliderTapped(_ value: CGFloat)
}

class HTZSliderView: UIView {

    ///  默认滑杆的颜色
    var maximumTrackTintColor: UIColor? {
        didSet {
            self.bgProgressView.backgroundColor = maximumTrackTintColor
        }
    }
    ///  滑杆进度颜色
    var minimumTrackTintColor: UIColor? {
        didSet {
            self.sliderProgressView.backgroundColor = minimumTrackTintColor
        }
    }
    ///  缓存进度颜色
    var bufferTrackTintColor: UIColor? {
        didSet {
            self.bufferProgressView.backgroundColor = bufferTrackTintColor
        }
    }
    
    ///  默认滑杆的图片
    var maximumTrackImage: UIImage? {
        didSet {
            self.bgProgressView.image = maximumTrackImage
            self.maximumTrackTintColor = UIColor.clear
        }
    }
    ///  滑杆进度的图片
    var minimumTrackImage: UIImage? {
        didSet {
            self.sliderProgressView.image = minimumTrackImage
            self.minimumTrackTintColor = UIColor.clear
        }
    }
    ///  缓存进度的图片
    var bufferTrackImage: UIImage? {
        didSet {
            self.bufferProgressView.image = bufferTrackImage
            self.bufferTrackTintColor = UIColor.clear
        }
    }
    
    ///  滑杆进度
    var value: CGFloat? {
        didSet {
            let finishValue  = self.bgProgressView.frame.size.width * value!
            self.sliderProgressView.width = finishValue
            
            let buttonX = (self.width - self.sliderButton.width) * value!
            self.sliderButton.x = buttonX
            
            self.lastPoint = self.sliderButton.center
        }
    }
    ///  缓存进度
    var bufferValue: CGFloat? {
        didSet {
            let finishValue = self.bgProgressView.width * bufferValue!
            self.bufferProgressView.width = finishValue
        }
    }
    
    ///  是否允许点击，默认是yes
    var allowTapped: Bool = true {
        didSet {
            if !allowTapped {
                self.removeGestureRecognizer(self.tapGesture!)
            }
        }
    }
    
    ///
    var sliderHeight: CGFloat? {
        didSet {
            self.bgProgressView.height = sliderHeight!
            self.bufferProgressView.height = sliderHeight!
            self.sliderProgressView.height = sliderHeight!
        }
    }
    
    weak var delegate: HTZSliderViewDelegate?
    
    /// 滑块的大小
    private let kSliderBtnWH = 19.0
    /// 间距
    private let kProgressMargin = 2.0
    /// 进度的宽度
//    private let kProgressW = self.frame.size.width - kProgressMargin
    /// 进度的高度
    private let kProgressH = 3.0
    
    /// 进度背景
    private lazy var bgProgressView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.gray
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    /// 缓存进度
    private lazy var bufferProgressView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.white
        imageView.clipsToBounds = true
        return imageView
    }()
    
    /// 滑动进度
    private lazy var sliderProgressView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.red
        imageView.clipsToBounds = true
        return imageView
    }()
    
    /// 滑块
    private lazy var sliderButton: SliderButton = {
        let button = SliderButton()
        button.addTarget(self, action: #selector(sliderBtnTouchBegin), for: UIControl.Event.touchDown)
        button.addTarget(self, action: #selector(sliderBtnTouchEnded), for: UIControl.Event.touchCancel)
        button.addTarget(self, action: #selector(sliderBtnTouchEnded), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(sliderBtnTouchEnded), for: UIControl.Event.touchUpOutside)
        button.addTarget(self, action: #selector(sliderBtnDragMoving), for: UIControl.Event.touchDragInside)
        return button
    }()
    
    private var lastPoint: CGPoint?
    
    private var tapGesture: UITapGestureRecognizer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    /// 设置滑块的属性
    ///
    /// - Parameters:
    ///   - image: 滑块背景
    ///   - state: state description
    func setBackgroundImage(image: UIImage?, state: UIControl.State) {
        self.sliderButton.setBackgroundImage(image, for: state)
        self.sliderButton.sizeToFit()
    }
    
    /// 滑块图片
    func setThumbImage(image: UIImage?, state: UIControl.State) {
        self.sliderButton.setImage(image, for: state)
        self.sliderButton.sizeToFit()
    }
    
    func showLoading() {
        self.sliderButton.showActivityAnim()
    }
    
    func hideLoading() {
       self.sliderButton.hideActivityAnim()
    }
    
    func showSliderBlock() {
        self.sliderButton.isHidden = false
    }
    
    func hideSliderBlock() {
        self.sliderButton.isHidden = true
    }
}

// MARK: - 点击事件
extension HTZSliderView {
    
    @objc private func sliderBtnTouchBegin() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("sliderTouchBegin:"))) {
            delegate.sliderTouchBegin(self.value!)
        }
    }
    
    @objc private func sliderBtnTouchEnded() {
        if let delegate = self.delegate, delegate.responds(to: Selector(("sliderTouchEnded:"))) {
            delegate.sliderTouchEnded(self.value!)
        }
    }
    
    @objc private func sliderBtnDragMoving(button: UIButton, event: UIEvent) {
        // 点击的位置
        let touches = event.allTouches!
        var point: CGPoint?
        for touch:AnyObject in touches {
            let t:UITouch = touch as! UITouch
            point = t.location(in: self)
        }
        // 获取进度值 由于btn是从 0-(self.width - btn.width)
        var value = (point!.x - button.width * 0.5) / (self.width - button.width)
        value = value >= 1.0 ? 1.0 : value <= 0.0 ? 0.0 : value
        self.value = value
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("sliderValueChanged:"))) {
            delegate.sliderValueChanged(self.value!)
        }
    }
    
    @objc private func tapped(tap: UITapGestureRecognizer) {
        
        let point = tap.location(in: self)
        // 获取进度
        var value = (point.x - self.bgProgressView.x) * 1.0 / self.bgProgressView.width
        value = value >= 1.0 ? 1.0 : value <= 0 ? 0 : value
        
        self.value = value
        
        if let delegate = self.delegate, delegate.responds(to: Selector(("sliderTapped:"))) {
            delegate.sliderTapped(self.value!)
        }
    }
}

extension HTZSliderView {
    
    private func configSubviews() {
        self.backgroundColor = .clear
        
        self.addSubview(self.bgProgressView)
        self.addSubview(self.bufferProgressView)
        self.addSubview(self.sliderProgressView)
        self.addSubview(self.sliderButton)
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(tap:)))
        self.addGestureRecognizer(self.tapGesture!)
        
        self.bgProgressView.frame = CGRect(x: kProgressMargin, y: 0, width: 0, height: kProgressH)
        
        self.bufferProgressView.frame = self.bgProgressView.frame
        
        self.sliderProgressView.frame = self.bgProgressView.frame
        
        self.sliderButton.frame = CGRect(x: 0, y: 0, width: kSliderBtnWH, height: kSliderBtnWH)
        
        self.sliderButton.hideActivityAnim()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.bgProgressView.center.y    = self.height * 0.5
        self.bufferProgressView.center.y = self.height * 0.5
        self.sliderProgressView.center.y = self.height * 0.5
        self.bgProgressView.width       = self.width - CGFloat(kProgressMargin * 2)
        self.sliderButton.center.y          = self.height * 0.5
    }
}


class SliderButton: UIButton {
    
    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        indicatorView.hidesWhenStopped = false
        indicatorView.isUserInteractionEnabled = false
        indicatorView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        indicatorView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        return indicatorView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(indicatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.indicatorView.center = CGPoint(x: self.width / 2, y: self.height / 2)
        self.indicatorView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
    }
    
    func showActivityAnim() {
        self.indicatorView.isHidden = false
        self.indicatorView.startAnimating()
    }
    
    func hideActivityAnim() {
        self.indicatorView.isHidden = true
        self.indicatorView.stopAnimating()
    }
    
    /// 重写此方法将按钮的点击范围扩大
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        var bounds = self.bounds
        
        // 扩大点击区域
        bounds = bounds.insetBy(dx: -20, dy: -20)
        
        // 若点击的点在新的bounds里面。就返回yes
        return bounds.contains(point)
    }
}
