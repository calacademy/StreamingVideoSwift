//
//  ViewController.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/18/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    var isPlaying = false
    var youTubeDataRequest:NSURLConnection!
    var data = NSMutableData()
    var buffering = Buffering(image: nil)
    var currentStreamIndex = 0
    var streams:[[String:String]]!
    var streamController = AVPlayerViewController()
    var streamPlayer:AVPlayer!
    var logo:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // @todo
        // load this off a server
        streams = [
            [
                "id": "jyWHDIECRYQ",
                "label": "Reef View"
            ],
            [
                "id": "TStjLJIc3DY",
                "label": "Lagoon View"
            ]
        ]
        
        loadYouTubeData(streams[currentStreamIndex]["id"]!)
    }
    
    func onExit() {
        print("onExit")
        
        // destroy stream
        stopObservingStreamPlayer()
        
        if (streamController.player != nil) {
            streamController.player = nil
            streamPlayer = nil
            streamController.view.removeFromSuperview()
        }
        
        // remove logo
        if (logo != nil) {
            logo.removeFromSuperview()
        }
        
        isPlaying = false
    }
    
    func onRestart() {
        print("onRestart")
        loadYouTubeData(streams[currentStreamIndex]["id"]!)
    }
    
    func onError(e: NSError) {
        print(e)
    }
    
    func loadYouTubeData(id: String){
        buffer(true)
        
        // clear
        self.data = NSMutableData()
        
        let urlPath = "https://youtube.com/get_video_info?video_id=" + id
        let url = NSURL(string: urlPath)!
        let request = NSURLRequest(URL: url)
        
        if (youTubeDataRequest != nil) {
            youTubeDataRequest.cancel()
        }
        
        youTubeDataRequest = NSURLConnection(request: request, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        self.data.appendData(data)
    }
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        onError(error)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        // split data from YouTube
        let datastring = NSString(data: data, encoding: NSUTF8StringEncoding)
        let arr = datastring?.componentsSeparatedByString("&") as Array!
        
        // search for "hlsvp"
        for part in arr {
            var varArr = part.componentsSeparatedByString("=")
            
            if (varArr[0] == "hlsvp") {
                // found video url, display it
                let foo = varArr[1]
                displayVideo(foo.stringByRemovingPercentEncoding!)
                break
            }
        }
    }
    
    func onMenu(sender: UITapGestureRecognizer) {
        print("onMenu")
        
        // re-enable default menu button behavior
        self.view.removeGestureRecognizer(sender)
    }
    
    func onSelect(sender: UITapGestureRecognizer) {
        // placeholder functionality
        currentStreamIndex++
        
        if (currentStreamIndex >= streams.count) {
            currentStreamIndex = 0;
        }
        
        loadYouTubeData(streams[currentStreamIndex]["id"]!)
    }
    
    func onSwipe(sender: UISwipeGestureRecognizer) {
        switch sender.direction {
            case UISwipeGestureRecognizerDirection.Left:
                print("left")
            case UISwipeGestureRecognizerDirection.Right:
                print("right")
            case UISwipeGestureRecognizerDirection.Up:
                print("up")
            case UISwipeGestureRecognizerDirection.Down:
                print("down")
            default:
                print("unknown")
        }
    }
    
    func addInteraction() {
        // remove any pre-existing recognizers
        if (self.view.gestureRecognizers != nil) {
            for recognizer in self.view.gestureRecognizers! {
                self.view.removeGestureRecognizer(recognizer)
            }
        }
        
        // tap
        let selectRecognizer = UITapGestureRecognizer(target: self, action:"onSelect:")
        selectRecognizer.allowedPressTypes = [
            NSNumber(integer: UIPressType.Select.rawValue)
        ];
        self.view.addGestureRecognizer(selectRecognizer)
        
        // menu
        // while debugging, a double-tap on the menu button is required to exit app
        // @see https://developer.apple.com/library/prerelease/tvos/releasenotes/General/RN-tvOSSDK-9.0/index.html
        let menuRecognizer = UITapGestureRecognizer(target: self, action:"onMenu:")
        menuRecognizer.allowedPressTypes = [
            NSNumber(integer: UIPressType.Menu.rawValue)
        ];
        self.view.addGestureRecognizer(menuRecognizer)
        
        // swipe
        let directions = [UISwipeGestureRecognizerDirection.Right, UISwipeGestureRecognizerDirection.Left, UISwipeGestureRecognizerDirection.Up, UISwipeGestureRecognizerDirection.Down];
        
        for direction in directions {
            let swipeRecognizer = UISwipeGestureRecognizer(target: self, action:"onSwipe:")
            swipeRecognizer.direction = direction
            self.view.addGestureRecognizer(swipeRecognizer)
        }
    }
    
    func addLogo() {
        let w:CGFloat = 220
        let h:CGFloat = 320
        
        let image = UIImage(named: "logo.png")
        logo = UIImageView(image: image!)
        
        // place
        let bounds: CGRect = UIScreen.mainScreen().bounds
        logo.frame = CGRect(x: bounds.size.width - w, y: 0, width: w, height: h)
        
        // fade in
        logo.alpha = 0
        
        UIView.animateWithDuration(1, delay: 2, options: .CurveEaseOut, animations: {
            self.logo.alpha = 0.65
        }, completion: nil)
        
        // add to stage
        self.view.addSubview(logo)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let stream = streamPlayer.currentItem!
        
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
            } else {
                // buffer full, start playing
                onPlay()
            }
        }
    }
    
    func onPlay() {
        buffer(false)
        
        if (isPlaying) {
            return
        }
        
        isPlaying = true
        
        // size
        let bounds: CGRect = UIScreen.mainScreen().bounds
        let w:CGFloat = bounds.size.width
        let h:CGFloat = bounds.size.height
        streamController.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        
        // fade in
        streamController.view.alpha = 0;
        
        UIView.animateWithDuration(1, delay: 1, options: .CurveEaseOut, animations: {
            self.streamController.view.alpha = 1
        }, completion: nil)
        
        self.view.addSubview(streamController.view)
        
        addLogo()
        addInteraction()
    }
    
    func stopObservingStreamPlayer() {
        if (streamPlayer != nil) {
            streamPlayer.currentItem!.removeObserver(self, forKeyPath:"playbackBufferEmpty")
            streamPlayer.currentItem!.removeObserver(self, forKeyPath:"status")
        }
    }
    
    func displayVideo(path: String) {
        let url:NSURL = NSURL(string: path)!
        
        stopObservingStreamPlayer()
        
        streamPlayer = AVPlayer(URL: url)
        streamPlayer.muted = true
        streamController.player = streamPlayer
        streamController.showsPlaybackControls = false
        
        streamPlayer.currentItem!.addObserver(self, forKeyPath:"playbackBufferEmpty", options:.Initial, context:nil)
        streamPlayer.currentItem!.addObserver(self, forKeyPath:"status", options:.Initial, context:nil)
        streamPlayer.play()
    }
    
    func buffer(boo: Bool) {
//        if (buffering.onStage == boo) {
//            return
//        }
        
        if (boo) {
            self.view.addSubview(buffering)
        } else {
            // buffering.removeFromSuperview()
        }
    }
}

