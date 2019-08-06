//
//  UIView+Extension.swift
//  htz
//
//  Created by 袁应荣 on 2019/6/11.
//  Copyright © 2019 袁应荣. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    var x:CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            self.frame.origin.x = newValue
        }
    }
    
    var y:CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            self.frame.origin.y = newValue
        }
    }
    
    var width:CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            self.frame.size.width = newValue
        }
        
    }
    
    var height:CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            self.frame.size.height = newValue
        }
    }
    
    var size:CGSize {
        get {
            return self.frame.size
        }
        set {
            self.frame.size = newValue
        }
    }
    
    var centerX:CGFloat {
        get {
            return self.center.x
        }
        set {
            self.centerX = newValue
        }
    }
    
    //    关联SB和XIB
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var shadowRadius:CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable var shadowOpacity:Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable var shadowColor:UIColor? {
        get {
            return layer.shadowColor != nil ? UIColor(cgColor:layer.shadowColor!) : nil
        }
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var shadowOffset:CGSize {
        get {
            return layer.shadowOffset
        }
        
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable var zPoition:CGFloat {
        get {
            return layer.zPosition
        }
        
        set {
            layer.zPosition = newValue
        }
    }
    class func createFromNib() -> UIView {
        return Bundle.main.loadNibNamed(NSStringFromClass(UIView.self), owner: nil, options: nil)?.first as! UIView
    }
}
