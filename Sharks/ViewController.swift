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
    var isObservingRate = false
    var youTubeDataRequest:NSURLConnection!
    var data = NSMutableData()
    var buffering = Buffering(image: nil)
    var currentStreamIndex = 0
    var streams:[[String:String]]!
    var streamController = StreamController()
    var logo:UIImageView!
    var streamViewContainer = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(streamViewContainer)
        streamController.subscribeToObservers(self)
        
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
        streamController.destroy()
        
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
                streamController.setStream(foo.stringByRemovingPercentEncoding!)
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
        let player = streamController.player!
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
            } else {
                // buffer full, start checking for rate
                if (isObservingRate) {
                    player.removeObserver(self, forKeyPath:"rate")
                }
                
                player.addObserver(self, forKeyPath:"rate", options:.Initial, context:nil)
                isObservingRate = true
            }
        }
        
        if (keyPath == "rate") {
            if (player.rate == 1.0) {
                // now we're playing
                player.removeObserver(self, forKeyPath:"rate")
                isObservingRate = false
                
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
        
        streamController.addToView(streamViewContainer)
        
        addLogo()
        addInteraction()
    }
    
    func buffer(boo: Bool) {
        if (buffering.onStage == boo) {
            return
        }
        
        buffering.show(boo, view: self.view)
    }
}

