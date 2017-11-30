//
//  SwitchButtonIOS.swift
//  Sharks
//
//  Created by Rotter, Greg on 2/26/16.
//  Copyright © 2016 Greg Rotter. All rights reserved.
//

import UIKit

class SwitchButtonIOS: SwitchButton {
    override init(frame: CGRect) {        
        super.init(frame: frame)
    }
    
    override internal func _addArrow() {
        let w:CGFloat = 47
        let h:CGFloat = 50
        
        _arrow = UIImageView(image: UIImage(named: "arrowios"))
        _arrow.alpha = 0.7
        
        _arrow.frame.origin.x = round((_w - w) / 2)
        _arrow.frame.origin.y = round((_w - h) / 2) - 5
        
        self.addSubview(_arrow)
    }
    
    override internal func _addLabel(_ label: String) {
        let h:CGFloat = 16
        
        _label = UILabel(frame: CGRect(x: _borderWidth, y: _w - _borderWidth - h - 5, width: _w - (_borderWidth * 2), height: h))
        _label.textColor = UIColor.white
        _label.textAlignment = NSTextAlignment.center
        _label.font = UIFont(name: "Whitney-Semibold", size: _labelSize)
        _label.text = label.uppercased()
        
        self.addSubview(_label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
