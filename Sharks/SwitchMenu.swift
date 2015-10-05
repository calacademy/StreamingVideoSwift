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
            let h = UIScreen.mainScreen().bounds.size.height
            
            // add
            for (i, stream) in streams.enumerate() {
                let btn = SwitchButton()
                btn.setup(id: stream["id"]!, label: stream["label"]!, pic: stream["asset"]!)
                
                btn.frame.origin.y = round((h / 2) - (btn.frame.size.height / 2)) - 10
                
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
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
    
    func select(id:String, animate:Bool) {
        if (_buttons != nil) {
            for btn in _buttons {
                if (btn.id == id) {
                    btn.activate(animate)
                } else {
                    btn.deactivate(animate)
                }
            }
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
