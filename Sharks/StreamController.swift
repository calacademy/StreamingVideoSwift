//
//  StreamController.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/25/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import AVKit

class StreamController: AVPlayerViewController {
    var observer = NSObject()
    var isObservingRate = false
    
    func subscribeToObservers(myObserver: NSObject) {
        observer = myObserver
    }
    
    func addToView(container: UIView) {
        // size
        let bounds: CGRect = UIScreen.mainScreen().bounds
        let w:CGFloat = bounds.size.width
        let h:CGFloat = bounds.size.height
        self.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        
        // fade in
        self.view.alpha = 0;
        
        UIView.animateWithDuration(0.8, delay: 1, options: .CurveEaseOut, animations: {
            self.view.alpha = 1
        }, completion: { _ in
            NSNotificationCenter.defaultCenter().postNotificationName("streamVisible", object: nil)
        })
        
        container.addSubview(self.view)
    }
    
    func setStream(path: String) {
        let url:NSURL = NSURL(string: path)!
        
        stopObservingStreamPlayer()
        
        let streamPlayer = AVPlayer(URL: url)
        streamPlayer.muted = true
        self.player = streamPlayer
        self.showsPlaybackControls = false
        
        startObservingStreamPlayer()
        streamPlayer.play()
    }
    
    func startObservingStreamPlayer() {
        self.player!.currentItem!.addObserver(observer, forKeyPath:"playbackBufferEmpty", options:.Initial, context:nil)
        self.player!.currentItem!.addObserver(observer, forKeyPath:"status", options:.Initial, context:nil)
    }
    
    func stopObservingStreamPlayer() {
        if (self.player != nil) {
            self.player!.currentItem!.removeObserver(observer, forKeyPath:"playbackBufferEmpty")
            self.player!.currentItem!.removeObserver(observer, forKeyPath:"status")
            
            if (isObservingRate) {
                self.player!.currentItem!.removeObserver(observer, forKeyPath:"rate")
            }
        }
    }
    
    func destroy() {
        // stopObservingStreamPlayer()
        
        if (self.player != nil) {
            self.player = nil
        }
        
        self.view.removeFromSuperview()
    }
}
