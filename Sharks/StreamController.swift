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
    fileprivate var _isReady = false
    fileprivate var _isFlat = false
    fileprivate var _isMinSecsElapsed = false
    
    fileprivate var _pollColorTimer:Timer!
    fileprivate var _pollVolumeFade:Timer!
    fileprivate var _pollMinSecs:Timer!
    fileprivate var _videoOutput:AVPlayerItemVideoOutput!
    
    var aspect:[String: CGFloat]!
    
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
    
    func scaleToFill() {
        let screenSize = UIScreen.main.bounds.size
        let w:CGFloat = ceil((aspect["width"]! * screenSize.height) / aspect["height"]!)
        
        if (w >= screenSize.width) {
            self.view.frame = CGRect(x: (screenSize.width - w), y: 0, width: w, height: screenSize.height)
        } else {
            let h:CGFloat = ceil((aspect["height"]! * screenSize.width) / aspect["width"]!)
            self.view.frame = CGRect(x: 0, y: (screenSize.height - h), width: screenSize.width, height: h)
        }
    }
    
    func addToView(_ container: UIView) {
        scaleToFill()
        
        // fade in
        self.view.alpha = 0
        
        UIView.animate(withDuration: 0.8, delay: 2.5, options: .curveEaseOut, animations: {
            self.view.alpha = 1
        }, completion: { _ in
            self.fadeVolume(fadeIn: true)
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
    
    func setStream(_ path: String, minSecs: NSNumber, isFlat: Bool) {
        _isPlaying = false
        _isReady = false
        _isMinSecsElapsed = false
        _isFlat = isFlat
        
        _stopKVO()
        
        if (_pollMinSecs != nil) {
            _pollMinSecs.invalidate()
        }
        
        _pollMinSecs = Timer.scheduledTimer(timeInterval: minSecs.doubleValue, target: self, selector: #selector(StreamController.onMinSecsReached), userInfo: nil, repeats: false)
        
        let url:URL = URL(string: path)!
        let streamPlayer = AVPlayer(url: url)
        
        streamPlayer.volume = 0
        self.player = streamPlayer
        
        _startKVO()
        streamPlayer.play()
    }
    
    @objc func onMinSecsReached() {
        _isMinSecsElapsed = true
        
        if (_isReady && !_isPlaying) {
            _onPlay()
        }
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
        if (_isMinSecsElapsed || _isFlat) {
            _isPlaying = true
            NotificationCenter.default.post(name: Notification.Name(rawValue: "streamPlaying"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self._onFlatComplete), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    @objc func _onFlatComplete() {
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
    
    @objc func checkColor() {
        let itemTime = _videoOutput.itemTime(forHostTime: CACurrentMediaTime())
        
        if (_videoOutput.hasNewPixelBuffer(forItemTime: itemTime)) {
            _pollColorTimer.invalidate()
            
            _isReady = true
            _onPlay()
        }
    }
    
    @objc func fadeVolumeIn() {
        self.player!.volume += 0.05
        
        if (self.player!.volume >= 1) {
            _pollVolumeFade.invalidate()
            self.player!.volume = 1
        }
    }
    @objc func fadeVolumeOut() {
        self.player!.volume -= 0.05
        
        if (self.player!.volume <= 0) {
            _pollVolumeFade.invalidate()
            self.player!.volume = 0
        }
    }
    
    func fadeVolume(fadeIn: Bool = true) {
        if (_pollVolumeFade != nil) {
            _pollVolumeFade.invalidate()
        }
        
        let timeInt = 0.05
        
        if (fadeIn) {
            _pollVolumeFade = Timer.scheduledTimer(timeInterval: timeInt, target: self, selector: #selector(StreamController.fadeVolumeIn), userInfo: nil, repeats: true)
        } else {
            _pollVolumeFade = Timer.scheduledTimer(timeInterval: timeInt, target: self, selector: #selector(StreamController.fadeVolumeOut), userInfo: nil, repeats: true)
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
    
    func destroyVolumeTimer() {
        if (_pollVolumeFade != nil) {
            _pollVolumeFade.invalidate()
        }
    }
    
    func destroy() {        
        if (_pollVolumeFade != nil) {
            _pollVolumeFade.invalidate()
        }
        
        if (_pollColorTimer != nil) {
            _pollColorTimer.invalidate()
        }
        
        if (_pollMinSecs != nil) {
            _pollMinSecs.invalidate()
        }
        
        _isPlaying = false
        _isReady = false
        _isFlat = false
        _isMinSecsElapsed = false
        
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
