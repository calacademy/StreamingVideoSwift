//
//  UITouchEndGestureRecognizer.swift
//  Sharks
//
//  Created by Rotter, Greg on 2/26/16.
//  Copyright © 2016 Greg Rotter. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class UITouchEndGestureRecognizer: UIGestureRecognizer {
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        if self.state == .Possible {
            self.state = .Recognized
        }
    }
}
