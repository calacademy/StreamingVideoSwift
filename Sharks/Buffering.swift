//
//  Buffering.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/24/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class Buffering: UIImageView {
    var onStage:Bool = false
    
    override init(image: UIImage?) {
        let logo = UIImage(named: "buffering.png")
        super.init(image: logo)
        
        _place()
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        if (self.superview == nil) {
            print("adding")
            
            // fade in
            self.alpha = 0
            
            UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseOut, animations: {
                self.alpha = 1
            }, completion: nil)
            
            // rotate
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotateAnimation.fromValue = 0.0
            rotateAnimation.toValue = CGFloat(M_PI * 2.0)
            rotateAnimation.duration = 1.25
            rotateAnimation.repeatCount = .infinity
            self.layer.addAnimation(rotateAnimation, forKey: nil)
            
            onStage = true
        }
    }
    override func didMoveToSuperview() {
        if (self.superview == nil) {
            print("removing")
            self.layer.removeAllAnimations()
            onStage = false
        }
    }
    
    private func _place() {
        let w:CGFloat = 90
        let h:CGFloat = 90
        
        // place
        let bounds: CGRect = UIScreen.mainScreen().bounds
        self.frame = CGRect(x: round((bounds.size.width - w) / 2), y: round((bounds.size.height - h) / 2) - 10, width: w, height: h)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
