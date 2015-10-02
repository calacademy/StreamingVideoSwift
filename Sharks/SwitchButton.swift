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
    
    override init(frame: CGRect) {
        let frame = CGRect(x: 0, y: 0, width: _w, height: _w)
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.blackColor()
    }
    
    func setup(label myLabel: NSString, pic myPic: NSString) {
        _pic = UIImageView(image: UIImage(named: myPic as String))
        self.addSubview(_pic)
        
        _addGradient()
        _addArrow()
        _addLabel(myLabel)
        
        // @see http://stackoverflow.com/questions/28934948/how-to-animate-bordercolor-change-in-swift
        _border = UIView(frame: frame)
        _border.layer.borderColor = UIColor.whiteColor().CGColor
        _border.layer.borderWidth = _borderWidth
        self.addSubview(_border)
        
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
    
    private func _addLabel(label: NSString) {
        let h:CGFloat = 30
        
        _label = UILabel(frame: CGRectMake(_borderWidth, _w - _borderWidth - h - 10, _w - (_borderWidth * 2), h))
        _label.textColor = UIColor.whiteColor()
        _label.textAlignment = NSTextAlignment.Center
        _label.font = UIFont(name: "Whitney-Semibold", size: 30)
        _label.text = (label as String).uppercaseString
        
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
