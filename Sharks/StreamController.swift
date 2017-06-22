//
//  StreamController.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/25/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import AVKit
import AVFoundation

class StreamController: AVPlayerViewController {
    fileprivate var _isPlaying = false
    fileprivate var _pollColorTimer:Timer!
    fileprivate var _videoOutput:AVPlayerItemVideoOutput!
    
    init() {
        super.init(nibName:nil, bundle:nil)
        
        // allow other apps to play audio
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryAmbient, with: AVAudioSessionCategoryOptions.mixWithOthers)
        
        self.showsPlaybackControls = false
        _videoOutput = AVPlayerItemVideoOutput()
        
        // can't override play/pause button without this
        self.view.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addToView(_ container: UIView) {
        // @todo
        // adjust to fill screen per aspect ratio
        
        // size
        let bounds: CGRect = UIScreen.main.bounds
        let w:CGFloat = bounds.size.width
        let h:CGFloat = bounds.size.height
        self.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        
        // fade in
        self.view.alpha = 0;
        
        UIView.animate(withDuration: 0.8, delay: 2.5, options: .curveEaseOut, animations: {
            self.view.alpha = 1
        }, completion: { _ in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "streamVisible"), object: nil)
        })
        
        container.addSubview(self.view)
        
    }
    
    func removeStaleViews(_ container: UIView) {
        // remove stale views
        var viewsToRemove = container.subviews
        
        if (viewsToRemove.count <= 1) {
            return
        }
        
        _stopKVO()
        
        // keep the last (top)
        viewsToRemove.remove(at: viewsToRemove.count - 1)
        
        for view in viewsToRemove {
            view.removeFromSuperview()
        }
        
        // re-enable stream listeners
        _startKVO()
    }
    
    func setStream(_ path: String) {
        _isPlaying = false
        _stopKVO()
        
        let url:URL = URL(string: path)!
        let streamPlayer = AVPlayer(url: url)
        
        streamPlayer.isMuted = true
        self.player = streamPlayer
        
        _startKVO()
        streamPlayer.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (self.player == nil) {
            return
        }
        
        let player = self.player!
        let stream = player.currentItem!
        
        if (keyPath == "status") {
            switch stream.status {
                case .unknown, .failed:
                    if (stream.error != nil) {
                        _onError(stream.error! as NSError)
                    }
                default:
                    break
            }
        }
        
        if (keyPath == "playbackBufferEmpty") {
            if (stream.isPlaybackBufferEmpty && _isPlaying) {
                _onError(NSError(domain: "playbackBufferEmpty", code: 1, userInfo: nil))
            }
            if (!stream.isPlaybackBufferEmpty && !_isPlaying) {
                _pollColor()
            }
        }
    }
    
    fileprivate func _onPlay() {
        _isPlaying = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: "streamPlaying"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self._onFlatComplete), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

    }
    
    func _onFlatComplete() {
        _isPlaying = false
        NotificationCenter.default.post(name: Notification.Name(rawValue: "flatComplete"), object: nil)
    }
    
    fileprivate func _onError(_ e: NSError) {
        _isPlaying = false
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "streamError"), object: nil, userInfo: [
            "error": e
        ])
    }
    
    fileprivate func _startKVO() {
        self.player!.currentItem!.addObserver(self, forKeyPath:"playbackBufferEmpty", options:.initial, context:nil)
        self.player!.currentItem!.addObserver(self, forKeyPath:"status", options:.initial, context:nil)
    }
    
    fileprivate func _stopKVO() {
        if (self.player != nil) {
            self.player!.currentItem!.removeObserver(self, forKeyPath:"playbackBufferEmpty")
            self.player!.currentItem!.removeObserver(self, forKeyPath:"status")
        }
    }
    
    func checkColor() {
        let itemTime = _videoOutput.itemTime(forHostTime: CACurrentMediaTime())
        
        if (_videoOutput.hasNewPixelBuffer(forItemTime: itemTime)) {
            _pollColorTimer.invalidate()
            
            // @todo
            // add delay in iOS?
            _onPlay()
        }
    }
    
    fileprivate func _pollColor() {
        self.player!.currentItem!.remove(_videoOutput)
        self.player!.currentItem!.add(_videoOutput)
        
        if (_pollColorTimer != nil) {
            _pollColorTimer.invalidate()
        }
        
        _pollColorTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(StreamController.checkColor), userInfo: nil, repeats: true)
    }
    
    func destroy() {        
        if (_pollColorTimer != nil) {
            _pollColorTimer.invalidate()
        }
        
        _isPlaying = false
        NotificationCenter.default.removeObserver(self)
        _stopKVO()
    }
    
    func destroyAndRemove() {
        destroy()
        
        if (self.player != nil) {
            self.player!.currentItem!.remove(_videoOutput)
            self.player = nil
        }
        
        self.view.removeFromSuperview()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
