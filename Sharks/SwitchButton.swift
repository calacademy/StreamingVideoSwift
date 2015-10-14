//
//  SwitchButton.swift
//  Sharks
//
//  Created by Rotter, Greg on 10/2/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class SwitchButton: UIView {
    private var _w:CGFloat = 400
    private var _borderWidth:CGFloat = 15
    private var _pic:UIImageView!
    private var _arrow:UIImageView!
    private var _border:UIView!
    private var _label:UILabel!
    private var _overlay:UIView!
    
    var isActive:Bool = true
    var id:String!
    
    override init(frame: CGRect) {
        let frame = CGRect(x: 0, y: 0, width: _w, height: _w)
        super.init(frame: frame)
        
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
    }
    
    func setup(id myID: String, label myLabel: String, pic asset: String) {
        self.id = myID
        
        if (asset.hasPrefix("http")) {
            // load remote
            _pic = UIImageView(image: UIImage(named: "reef"))
            _pic.download(asset)
        } else {
            _pic = UIImageView(image: UIImage(named: asset))
        }
        
        _pic.frame.origin.x = -35
        _pic.frame.origin.y = -35
        self.addSubview(_pic)
        
        _addGradient()
        _addArrow()
        _addLabel(myLabel)
        
        _overlay = UIView(frame: self.frame)
        _overlay.backgroundColor = UIColor.blackColor()
        self.addSubview(_overlay)
        
        _border = UIView(frame: self.frame)
        _border.layer.borderColor = UIColor.whiteColor().CGColor
        _border.layer.borderWidth = _borderWidth
        self.addSubview(_border)
        
        deactivate(false)
    }
    
    func destroy() {
        self.removeFromSuperview()
    }
    
    func activate(animate: Bool) {
        if (isActive) {
            return
        }
        
        self._border.layer.borderColor = UIColor(red: 0, green: 255, blue: 255, alpha: 1).CGColor
        
        if (animate) {
            UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseOut, animations: {
                self._pic.transform = CGAffineTransformMakeScale(0.9, 0.9)
            }, completion: nil)
            
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
                self._overlay.alpha = 0
                self._arrow.alpha = 0.7
            }, completion: nil)
        } else {
            self._pic.transform = CGAffineTransformMakeScale(0.9, 0.9)
            self._overlay.alpha = 0
            self._arrow.alpha = 0.7
        }

        isActive = true
    }
    
    func deactivate(animate: Bool) {
        if (!isActive) {
            return
        }
        
        self._border.layer.borderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1).CGColor
        
        if (animate) {
            UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseOut, animations: {
                self._pic.transform = CGAffineTransformMakeScale(0.8, 0.8)
                self._overlay.alpha = 0.25
                self._arrow.alpha = 0
            }, completion: nil)
        } else {
            self._pic.transform = CGAffineTransformMakeScale(0.8, 0.8)
            self._overlay.alpha = 0.25
            self._arrow.alpha = 0
        }
        
        isActive = false
    }
    
    private func _addGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRectMake(0, 0, _w, _w)
        
        var colors = [CGColor]()
        colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor)
        colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: 0.75).CGColor)
        
        gradient.colors = colors
        gradient.startPoint = CGPointMake(0.5, 0.1)
        gradient.endPoint = CGPointMake(0.5, 0.9)
        
        self.layer.addSublayer(gradient)
    }
    
    private func _addArrow() {
        let w:CGFloat = 92
        let h:CGFloat = 97
        
        _arrow = UIImageView(image: UIImage(named: "arrow"))
        _arrow.alpha = 0.7
        
        _arrow.frame.origin.x = round((_w - w) / 2)
        _arrow.frame.origin.y = round((_w - h) / 2) - 6
        
        self.addSubview(_arrow)
    }
    
    private func _addLabel(label: String) {
        let h:CGFloat = 30
        
        _label = UILabel(frame: CGRectMake(_borderWidth, _w - _borderWidth - h - 10, _w - (_borderWidth * 2), h))
        _label.textColor = UIColor.whiteColor()
        _label.textAlignment = NSTextAlignment.Center
        _label.font = UIFont(name: "Whitney-Semibold", size: 30)
        _label.text = label.uppercaseString
        
        self.addSubview(_label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
