//
//  SwitchButton.swift
//  Sharks
//
//  Created by Rotter, Greg on 10/2/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class SwitchMenu: UIView {
    #if os(iOS)
        fileprivate var _margin:CGFloat = 15
    #else
        fileprivate var _margin:CGFloat = 30
    #endif
    
    var buttons:[SwitchButton]!
    var onStage:Bool = false
    var currentIndex:Int = 0
    var slug = "unknown"
    
    var streams:[[String:String]] = [] {
        willSet (newStreams) {
            if (onStage) {
                return
            }
            
            // clear all
            if (buttons != nil) {
                for btn in buttons {
                    btn.destroy()
                }
            }
            
            buttons = []
        }
        didSet {
            if (onStage) {
                return
            }
            
            let w = UIScreen.main.bounds.size.width
            
            // add
            for (i, stream) in streams.enumerated() {
                #if os(iOS)
                    let btn = SwitchButtonIOS()
                #else
                    let btn = SwitchButton()
                #endif
                
                btn.setup(id: stream["id"]!, label: stream["label"]!, pic: slug + "-" + stream["asset"]!)
                
                // btn.frame.origin.y = getTargetY(btn)
                
                btn.frame.origin.x = CGFloat(i) * btn.frame.size.width
                btn.frame.origin.x += round((w - ((CGFloat(streams.count) * (btn.frame.size.width + _margin)) - _margin)) / 2)
                
                // spacing
                btn.frame.origin.x += _margin * CGFloat(i)
                
                buttons.append(btn)
                self.addSubview(btn)
            }
        }
    }
    
    override init(frame: CGRect) {
        let bounds: CGRect = UIScreen.main.bounds
        super.init(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
    }
    
    func getTargetY(_ btn: SwitchButton) -> CGFloat {
        #if os(iOS)
            let offset: CGFloat = 3
        #else
            let offset: CGFloat = 10
        #endif
        
        let h = UIScreen.main.bounds.size.height
        return round((h - btn.frame.size.height) / 2) - offset
    }
    
    func select(_ id:String, animate:Bool) {
        if (!onStage) {
            return
        }
        
        if (buttons != nil) {
            for (i, btn) in buttons.enumerated() {
                if (btn.id == id) {
                    btn.activate(animate)
                    currentIndex = i
                } else {
                    btn.deactivate(animate)
                }
            }
        }
    }
    
    func navigate(_ direction:String) {
        if (!onStage) {
            return
        }
        
        var i = currentIndex
        
        // increment
        if (direction == "left") {
            i -= 1
        } else {
            i += 1
        }
        
        // left
        if (i < 0) {
            return
        }
        
        // right
        if (i > buttons.count - 1) {
            return
        }
        
        select(buttons[i].id, animate: true)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if (self.superview == nil) {
            onStage = true
            NotificationCenter.default.post(name: Notification.Name(rawValue: "overlayVisible"), object: nil)
            
            // fade in bg
            self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
            
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut, animations: {
                self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            }, completion: nil)
            
            // button intro
            for (i, btn) in buttons.enumerated() {
                let targetY = getTargetY(btn)
                
                btn.frame.origin.y = targetY + 130
                btn.alpha = 0
                
                let d = CGFloat(i) * 0.12
                
                UIView.animate(withDuration: 0.4, delay: Double(d), options: .curveEaseOut, animations: {
                    btn.frame.origin.y = targetY
                }, completion: nil)
                
                UIView.animate(withDuration: 0.6, delay: Double(d), options: .curveEaseOut, animations: {
                    btn.alpha = 1
                }, completion: nil)
            }
        }
    }
    
    override func didMoveToSuperview() {
        if (self.superview == nil) {
            onStage = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: "overlayHidden"), object: nil)
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
