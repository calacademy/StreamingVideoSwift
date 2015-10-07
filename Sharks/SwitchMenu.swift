//
//  SwitchButton.swift
//  Sharks
//
//  Created by Rotter, Greg on 10/2/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class SwitchMenu: UIView {
    private var _margin:CGFloat = 30
    private var _buttons:[SwitchButton]!
    
    var onStage:Bool = false
    var currentIndex:Int = 0
    
    var streams:[[String:String]] = [] {
        willSet (newStreams) {
            // clear all
            if (_buttons != nil) {
                for btn in _buttons {
                    btn.destroy()
                }
            }
            
            _buttons = []
        }
        didSet {
            let w = UIScreen.mainScreen().bounds.size.width
            
            // add
            for (i, stream) in streams.enumerate() {
                let btn = SwitchButton()
                btn.setup(id: stream["id"]!, label: stream["label"]!, pic: stream["asset"]!)
                
                // btn.frame.origin.y = getTargetY(btn)
                
                btn.frame.origin.x = CGFloat(i) * btn.frame.size.width
                btn.frame.origin.x += round((w / 2) - (((CGFloat(streams.count) * (btn.frame.size.width + _margin)) - _margin) / 2))
                
                // spacing
                if (i > 0) {
                    btn.frame.origin.x += _margin
                }
                
                _buttons.append(btn)
                self.addSubview(btn)
            }
        }
    }
    
    override init(frame: CGRect) {
        let bounds: CGRect = UIScreen.mainScreen().bounds
        super.init(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
    }
    
    func getTargetY(btn: SwitchButton) -> CGFloat {
        let h = UIScreen.mainScreen().bounds.size.height
        return (round((h / 2) - (btn.frame.size.height / 2)) - 10)
    }
    
    func select(id:String, animate:Bool) {
        if (!onStage) {
            return
        }
        
        if (_buttons != nil) {
            for (i, btn) in _buttons.enumerate() {
                if (btn.id == id) {
                    btn.activate(animate)
                    currentIndex = i
                } else {
                    btn.deactivate(animate)
                }
            }
        }
    }
    
    func navigate(direction:String) {
        if (!onStage) {
            return
        }
        
        var i = currentIndex
        
        // increment
        if (direction == "left") {
            i--
        } else {
            i++
        }
        
        // left
        if (i < 0) {
            return
        }
        
        // right
        if (i > _buttons.count - 1) {
            return
        }
        
        select(_buttons[i].id, animate: true)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        if (self.superview == nil) {
            onStage = true
            NSNotificationCenter.defaultCenter().postNotificationName("overlayVisible", object: nil)
            
            // fade in bg
            self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
            
            UIView.animateWithDuration(0.8, delay: 0, options: .CurveEaseOut, animations: {
                self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            }, completion: nil)
            
            // button intro
            for (i, btn) in _buttons.enumerate() {
                let targetY = getTargetY(btn)
                
                btn.frame.origin.y = targetY + 125
                btn.alpha = 0
                
                let d = CGFloat(i) * 0.15
                
                UIView.animateWithDuration(0.4, delay: Double(d), options: .CurveEaseOut, animations: {
                    btn.frame.origin.y = targetY
                }, completion: nil)
                
                UIView.animateWithDuration(0.6, delay: Double(d), options: .CurveEaseOut, animations: {
                    btn.alpha = 1
                }, completion: nil)
            }
        }
    }
    override func didMoveToSuperview() {
        if (self.superview == nil) {
            onStage = false
            NSNotificationCenter.defaultCenter().postNotificationName("overlayHidden", object: nil)
        }
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
