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
    // add logo and interaction once only
    var isFirstPlay = true
    
    // prevent crazy clicks
    var isTransitioning = true
    
    var buffering = Buffering(image: nil)
    var currentStreamIndex = 0
    var streams:[[String:String]]!
    
    var logo:UIImageView!
    var streamViewContainer = UIView()
    
    var streamData = StreamData()
    var streamController:StreamController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onStreamPlay", name:"streamPlaying", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onStreamVisible", name:"streamVisible", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onStreamError:", name:"streamError", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onDataError", name:"dataError", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onData:", name:"dataLoaded", object: nil)
        
        self.view.addSubview(streamViewContainer)
        
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
    
    func loadYouTubeData(id: String){
        isTransitioning = true
        buffer(true)
        streamData.connect(id)
    }
    
    func onExit() {
        print("onExit")
        
        streamData.destroy()
        
        // destroy stream
        if (streamController != nil) {
            streamController.destroyAndRemove()
            streamController = nil
        }
        
        // remove logo
        if (logo != nil) {
            logo.removeFromSuperview()
        }
        
        isTransitioning = false
        isFirstPlay = true
    }
    
    func onRestart() {
        print("onRestart")
        loadYouTubeData(streams[currentStreamIndex]["id"]!)
    }
    
    func onDataError() {
        onError(NSError(domain: "dataError", code: 1, userInfo: nil))
    }
    
    func onStreamError(notification: NSNotification) {
        let obj = notification.userInfo as! AnyObject
        let error = obj["error"] as! NSError
        
        onError(error)
    }
    
    func onError(e: NSError) {
        // @todo
        // track attempts
        switch e.domain {
            case "dataError":
                print("dataError")
            case "playbackBufferEmpty":
                print("buffer empty. attempting to reload…")
                loadYouTubeData(streams[currentStreamIndex]["id"]!)
            default:
                print("unknown stream error. attempting to reload…")
                loadYouTubeData(streams[currentStreamIndex]["id"]!)
                break
        }
    }
    
    func onData(notification: NSNotification) {
        let obj = notification.userInfo as! AnyObject
        let url = obj["url"] as! String
        
        if (streamController != nil) {
            streamController.destroy()
        }
        
        streamController = StreamController()
        streamController.setStream(url)
    }
    
    func onStreamPlay() {
        buffer(false)
        streamController.addToView(streamViewContainer)
        
        if (isFirstPlay) {
            addLogo()
            addInteraction()
            isFirstPlay = false;
        }
    }
    
    func onStreamVisible() {
        streamController.removeStaleViews(streamViewContainer)
        isTransitioning = false
    }
    
    func onMenu(sender: UITapGestureRecognizer) {
        print("onMenu")
        
        // re-enable default menu button behavior
        self.view.removeGestureRecognizer(sender)
    }
    
    func onSelect(sender: UITapGestureRecognizer) {
        if (isTransitioning) {
            return
        }
        
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
        
        UIView.animateWithDuration(0.8, delay: 3, options: .CurveEaseOut, animations: {
            self.logo.alpha = 0.65
        }, completion: nil)
        
        // add to stage
        self.view.addSubview(logo)
    }
    
    func buffer(boo: Bool) {
        if (buffering.onStage == boo) {
            return
        }
        
        buffering.show(boo, view: self.view)
    }
}

