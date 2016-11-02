//
//  UITouchEndGestureRecognizer.swift
//  Sharks
//
//  Created by Rotter, Greg on 2/26/16.
//  Copyright © 2016 Greg Rotter. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class UITouchEndGestureRecognizer: UIGestureRecognizer {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            self.state = .recognized
        }
    }
}
