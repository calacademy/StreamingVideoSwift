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
    private var _isOverlayVisible:Bool = false
    private var _timer:NSTimer!
    
    override init(image: UIImage?) {
        #if os(iOS)
            let logo = UIImage(named: "bufferingios")
        #elseif os(tvOS)
            let logo = UIImage(named: "buffering")
        #endif
        
        super.init(image: logo)
        
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 22.0

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onOverlayVisible", name:"overlayVisible", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onOverlayHidden", name:"overlayHidden", object: nil)
        
        _place()
    }
    
    func onOverlayVisible() {
        _isOverlayVisible = true
        
        if (onStage) {
            // self.layer.removeAllAnimations()
            self.alpha = 0
        }
    }
    
    func onOverlayHidden() {
        _isOverlayVisible = false

        if (onStage) {
            // self.layer.removeAllAnimations()
            
            UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseOut, animations: {
                self.alpha = 1
            }, completion: nil)
        }
    }
    
    func show(boo: Bool, view: UIView) {
        if (_timer != nil) {
            _timer.invalidate()
            _timer = nil
        }
        
        if (boo) {
            view.addSubview(self)
        } else {
            // delay before removing
            self._timer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: "removeFromSuperview", userInfo: nil, repeats: false)
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        if (self.superview == nil) {
            // fade in
            self.alpha = 0
            
            if (!_isOverlayVisible) {
                UIView.animateWithDuration(0.6, delay: 0, options: .CurveEaseOut, animations: {
                    self.alpha = 1
                }, completion: nil)
            }
            
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
        #if os(iOS)
            let w:CGFloat = 45
            let h:CGFloat = 45
            let offset:CGFloat = 5
        #elseif os(tvOS)
            let w:CGFloat = 90
            let h:CGFloat = 90
            let offset:CGFloat = 10
        #endif
        
        // place
        let bounds: CGRect = UIScreen.mainScreen().bounds
        self.frame = CGRect(x: round((bounds.size.width - w) / 2), y: round((bounds.size.height - h) / 2) - offset, width: w, height: h)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
