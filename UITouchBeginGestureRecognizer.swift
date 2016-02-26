//
//  UITouchBeginGestureRecognizer.swift
//  Sharks
//
//  Created by Rotter, Greg on 2/25/16.
//  Copyright © 2016 Greg Rotter. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class UITouchBeginGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        if self.state == .Possible {
            self.state = .Recognized
        }
    }
}
