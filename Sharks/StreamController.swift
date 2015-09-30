//
//  StreamController.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/25/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import AVKit

class StreamController: AVPlayerViewController {
    var isPlaying = false
    
    func addToView(container: UIView) {
        // size
        let bounds: CGRect = UIScreen.mainScreen().bounds
        let w:CGFloat = bounds.size.width
        let h:CGFloat = bounds.size.height
        self.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        
        // fade in
        self.view.alpha = 0;
        
        UIView.animateWithDuration(0.8, delay: 2.5, options: .CurveEaseOut, animations: {
            self.view.alpha = 1
        }, completion: { _ in
            NSNotificationCenter.defaultCenter().postNotificationName("streamVisible", object: nil)
        })
        
        container.addSubview(self.view)
        
    }
    
    func setStream(path: String) {
        isPlaying = false
        stopKVO()
        
        let url:NSURL = NSURL(string: path)!
        let streamPlayer = AVPlayer(URL: url)
        streamPlayer.muted = true
        self.player = streamPlayer
        self.showsPlaybackControls = false
        
        startKVO()
        streamPlayer.play()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let player = self.player!
        let stream = player.currentItem!
        
        if (keyPath == "status") {
            switch stream.status {
            case .Unknown:
                if (stream.error != nil) {
                    onError(stream.error!)
                }
            case .Failed:
                onError(stream.error!)
            default:
                break
            }
        }
        
        if (keyPath == "playbackBufferEmpty") {
            if (stream.playbackBufferEmpty && isPlaying) {
                onError(NSError(domain: "playbackBufferEmpty", code: 1, userInfo: nil))
            }
            if (!stream.playbackBufferEmpty && !isPlaying) {
                onPlay()
            }
        }
    }
    
    func onPlay() {
        isPlaying = true
        NSNotificationCenter.defaultCenter().postNotificationName("streamPlaying", object: nil)
    }
    
    func onError(e: NSError) {
        isPlaying = false
        
        NSNotificationCenter.defaultCenter().postNotificationName("streamError", object: nil, userInfo: [
            "error": e
        ])
    }
    
    func startKVO() {
        self.player!.currentItem!.addObserver(self, forKeyPath:"playbackBufferEmpty", options:.Initial, context:nil)
        self.player!.currentItem!.addObserver(self, forKeyPath:"status", options:.Initial, context:nil)
    }
    
    func stopKVO() {
        if (self.player != nil) {
            self.player!.currentItem!.removeObserver(self, forKeyPath:"playbackBufferEmpty")
            self.player!.currentItem!.removeObserver(self, forKeyPath:"status")
        }
    }
    
    func destroy() {
        isPlaying = false
        stopKVO()
        
        if (self.player != nil) {
            self.player = nil
        }
        
        self.view.removeFromSuperview()
    }
}
