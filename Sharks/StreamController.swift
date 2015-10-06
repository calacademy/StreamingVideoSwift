//
//  StreamController.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/25/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import AVKit

class StreamController: AVPlayerViewController {
    private var _isPlaying = false
    
    init() {
        super.init(nibName:nil, bundle:nil)
        
        self.showsPlaybackControls = false
        
        // can't override play/pause button without this
        self.view.userInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
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
    
    func removeStaleViews(container: UIView) {
        // remove stale views
        var viewsToRemove = container.subviews
        
        if (viewsToRemove.count <= 1) {
            return
        }
        
        _stopKVO()
        
        // keep the last (top)
        viewsToRemove.removeAtIndex(viewsToRemove.count - 1)
        
        for view in viewsToRemove {
            view.removeFromSuperview()
        }
        
        // re-enable stream listeners
        _startKVO()
    }
    
    func setStream(path: String) {
        _isPlaying = false
        _stopKVO()
        
        let url:NSURL = NSURL(string: path)!
        let streamPlayer = AVPlayer(URL: url)
        streamPlayer.muted = true
        self.player = streamPlayer
        
        _startKVO()
        streamPlayer.play()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let player = self.player!
        let stream = player.currentItem!
        
        if (keyPath == "status") {
            switch stream.status {
                case .Unknown, .Failed:
                    if (stream.error != nil) {
                        _onError(stream.error!)
                    }
                default:
                    break
            }
        }
        
        if (keyPath == "playbackBufferEmpty") {
            if (stream.playbackBufferEmpty && _isPlaying) {
                _onError(NSError(domain: "playbackBufferEmpty", code: 1, userInfo: nil))
            }
            if (!stream.playbackBufferEmpty && !_isPlaying) {
                _onPlay()
            }
        }
    }
    
    private func _onPlay() {
        _isPlaying = true
        NSNotificationCenter.defaultCenter().postNotificationName("streamPlaying", object: nil)
    }
    
    private func _onError(e: NSError) {
        _isPlaying = false
        
        NSNotificationCenter.defaultCenter().postNotificationName("streamError", object: nil, userInfo: [
            "error": e
        ])
    }
    
    private func _startKVO() {
        self.player!.currentItem!.addObserver(self, forKeyPath:"playbackBufferEmpty", options:.Initial, context:nil)
        self.player!.currentItem!.addObserver(self, forKeyPath:"status", options:.Initial, context:nil)
    }
    
    private func _stopKVO() {
        if (self.player != nil) {
            self.player!.currentItem!.removeObserver(self, forKeyPath:"playbackBufferEmpty")
            self.player!.currentItem!.removeObserver(self, forKeyPath:"status")
        }
    }
    
    func destroy() {
        _isPlaying = false
        _stopKVO()
    }
    
    func destroyAndRemove() {
        destroy()
        
        if (self.player != nil) {
            self.player = nil
        }
        
        self.view.removeFromSuperview()
    }
}
