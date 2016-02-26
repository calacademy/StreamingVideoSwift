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
    
    override internal func _addLabel(label: String) {
        let h:CGFloat = 16
        
        _label = UILabel(frame: CGRectMake(_borderWidth, _w - _borderWidth - h - 5, _w - (_borderWidth * 2), h))
        _label.textColor = UIColor.whiteColor()
        _label.textAlignment = NSTextAlignment.Center
        _label.font = UIFont(name: "Whitney-Semibold", size: 16)
        _label.text = label.uppercaseString
        
        self.addSubview(_label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
