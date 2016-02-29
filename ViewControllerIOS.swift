//
//  ViewControllerIOS.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/18/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit
import AVKit

class ViewControllerIOS: ViewController, UIGestureRecognizerDelegate {
    override func addLogo() {
        let offset:CGFloat = 6
        let w:CGFloat = 87
        let h:CGFloat = 135
        
        let image = UIImage(named: "logoios")
        logo = UIImageView(image: image!)
        
        placeLogo(w, h: h, offsetX: offset, offsetY: offset - 1)
    }
    
    func onTouchBegin(sender: UIGestureRecognizer) {
        let btn = sender.view as! SwitchButton
        btn.isBeingPressed = true
        
        if (btn.isActive) {
            return
        }
        
        btn.activate(true)
        
        // deactivate other btns
        for otherBtn in menu.buttons {
            if (otherBtn.id != btn.id) {
                otherBtn.deactivate(true)
            }
        }
    }
    
    func onTouchEnd(sender: UIGestureRecognizer) {
        let btn = sender.view as! SwitchButton
        
        if (!btn.isBeingPressed) {
            return
        }
        
        btn.isBeingPressed = false
        menu.select(btn.id, animate: false)
        onSelect(sender)
    }
    
    override func addInteraction() {
        // remove any pre-existing recognizers
        if (self.view.gestureRecognizers != nil) {
            for recognizer in self.view.gestureRecognizers! {
                self.view.removeGestureRecognizer(recognizer)
            }
        }
        
        for btn in menu.buttons {
            if (btn.gestureRecognizers != nil) {
                for recognizer in btn.gestureRecognizers! {
                    btn.removeGestureRecognizer(recognizer)
                }
            }
        }
        
        if (streamData.streams.count < 2) {
            // no need for a menu
            return
        }
        
        // tap to open menu
        let selectRecognizer = UITapGestureRecognizer(target: self, action:"onSelect:")
        self.view.addGestureRecognizer(selectRecognizer)
        
        // add gestures to menu items
        for btn in menu.buttons {
            let begin = UITouchBeginGestureRecognizer(target: self, action:"onTouchBegin:")
            begin.delegate = self
            btn.addGestureRecognizer(begin)
            
            let end = UITouchEndGestureRecognizer(target: self, action:"onTouchEnd:")
            btn.addGestureRecognizer(end)
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

