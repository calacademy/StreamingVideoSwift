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
    var menuRecognizer:UIGestureRecognizer!
    
    let currentStreamIndexDefaultsKey = "currentStreamIndex"
    var defaults = NSUserDefaults.standardUserDefaults()
    
    var logo:UIImageView!
    var streamViewContainer = UIView()
    
    var menu = SwitchMenu()
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
                "label": "Reef View",
                "asset": "reef"
            ],
            [
                "id": "TStjLJIc3DY",
                "label": "Lagoon View",
                "asset": "lagoon"
            ]
        ]
        
        menu.streams = streams
        retrieveDefaults()
        loadYouTubeData(streams[currentStreamIndex]["id"]!)
    }
    
    func retrieveDefaults() {
        var savedIndex = defaults.integerForKey(currentStreamIndexDefaultsKey)
        
        // integerForKey returns 0 if key not found
        if (savedIndex > 0) {
            print("default stream retrieved: " + String(savedIndex))
            savedIndex--
            
            if (savedIndex >= streams.count) {
                print("retrieved stream no longer exists")
                savedIndex = 0
            }
        }
        
        currentStreamIndex = savedIndex
    }
    
    func loadYouTubeData(id: String){
        isTransitioning = true
        buffer(true)
        streamData.connect(id)
        
        // set as default
        defaults.setInteger(currentStreamIndex + 1, forKey: currentStreamIndexDefaultsKey)
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
        
        menu.removeFromSuperview()
        
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
                print("data error. attempting to reload…")
                loadYouTubeData(streams[currentStreamIndex]["id"]!)
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
        if (streamController != nil) {
            streamController.removeStaleViews(streamViewContainer)
        }
        
        isTransitioning = false
    }
    
    func onMenu(sender: UITapGestureRecognizer) {
        // add menu
        self.view.addSubview(menu)
        
        // select current stream
        menu.select(streams[currentStreamIndex]["id"]!, animate: false)
        
        // re-enable default menu button behavior
        if (menuRecognizer != nil) {
            self.view.removeGestureRecognizer(menuRecognizer)
        }
    }
    
    func onSelect(sender: UITapGestureRecognizer) {
        // open menu if not visible
        if (!menu.onStage) {
            onMenu(sender)
            return
        }
        
        if (currentStreamIndex != menu.currentIndex) {
            // prevent crazy clicks
            if (!isTransitioning) {
                // switch streams
                currentStreamIndex = menu.currentIndex
                loadYouTubeData(streams[currentStreamIndex]["id"]!)
            }
        }
        
        // remove menu
        menu.removeFromSuperview()
        
        // re-enable menu button
        addMenuButtonInteraction()
    }
    
    func onSwipe(sender: UISwipeGestureRecognizer) {
        switch sender.direction {
            case UISwipeGestureRecognizerDirection.Left,
            UISwipeGestureRecognizerDirection.Down:
                menu.navigate("left")
            case UISwipeGestureRecognizerDirection.Right,
            UISwipeGestureRecognizerDirection.Up:
                menu.navigate("right")
            default:
                print("unknown")
        }
    }
    
    func addMenuButtonInteraction() {
        // while debugging, a double-tap on the menu button is required to exit app
        // @see https://developer.apple.com/library/prerelease/tvos/releasenotes/General/RN-tvOSSDK-9.0/index.html
        if (menuRecognizer != nil) {
            self.view.removeGestureRecognizer(menuRecognizer)
        }
        
        menuRecognizer = UITapGestureRecognizer(target: self, action:"onMenu:")
        
        menuRecognizer.allowedPressTypes = [
            NSNumber(integer: UIPressType.Menu.rawValue)
        ];
        
        self.view.addGestureRecognizer(menuRecognizer)
    }
    
    func addInteraction() {
        // remove any pre-existing recognizers
        if (self.view.gestureRecognizers != nil) {
            for recognizer in self.view.gestureRecognizers! {
                self.view.removeGestureRecognizer(recognizer)
            }
        }
        
        // menu
        addMenuButtonInteraction()
        
        // tap
        let selectRecognizer = UITapGestureRecognizer(target: self, action:"onSelect:")
        selectRecognizer.allowedPressTypes = [
            NSNumber(integer: UIPressType.PlayPause.rawValue),
            NSNumber(integer: UIPressType.Select.rawValue)
        ];
        self.view.addGestureRecognizer(selectRecognizer)
        
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
        
        let image = UIImage(named: "logo")
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

