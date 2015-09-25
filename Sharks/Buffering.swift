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
    var timer:NSTimer!
    
    override init(image: UIImage?) {
        let logo = UIImage(named: "buffering.png")
        super.init(image: logo)
        
        _place()
    }
    
    func show(boo: Bool, view: UIView) {
        if (timer != nil) {
            timer.invalidate()
            timer = nil
        }
        
        if (boo) {
            view.addSubview(self)
        } else {
            // delay before removing
            self.timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: "removeFromSuperview", userInfo: nil, repeats: false)
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        if (self.superview == nil) {
            // fade in
            self.alpha = 0
            
            UIView.animateWithDuration(0.6, delay: 0, options: .CurveEaseOut, animations: {
                self.alpha = 1
            }, completion: nil)
            
            // rotate
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotateAnimation.fromValue = 0.0
            rotateAnimation.toValue = CGFloat(M_PI * 2.0)
            rotateAnimation.duration = 1
            rotateAnimation.repeatCount = .infinity
            self.layer.addAnimation(rotateAnimation, forKey: nil)
            
            onStage = true
        }
    }
    override func didMoveToSuperview() {
        if (self.superview == nil) {
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
