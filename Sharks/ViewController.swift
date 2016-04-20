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
    var menuRecognizer:UIGestureRecognizer!
    
    let currentStreamIndexDefaultsKey = "currentStreamIndex"
    var defaults = NSUserDefaults.standardUserDefaults()
    
    var logo:UIImageView!
    var streamViewContainer = UIView()
    
    var menu = SwitchMenu()
    var streamData = StreamData()
    var streamController:StreamController!
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(white: 1, alpha: 0)
        self.view.layer.contents = UIImage(named: "launch")?.CGImage
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onStreamPlay), name:"streamPlaying", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onStreamVisible), name:"streamVisible", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onStreamError(_:)), name:"streamError", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onDataError(_:)), name:"dataError", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onConfigData(_:)), name:"configDataLoaded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.onHLSData(_:)), name:"hlsDataLoaded", object: nil)
        
        self.view.addSubview(streamViewContainer)
        loadConfig()
    }
    
    func getDefaultStreamIndex() -> Int {
        var savedIndex = defaults.integerForKey(currentStreamIndexDefaultsKey)
        
        // integerForKey returns 0 if key not found
        if (savedIndex > 0) {
            print("NSUserDefaults stream retrieved: " + String(savedIndex))
            savedIndex -= 1
            
            if (savedIndex >= streamData.streams.count) {
                print("NSUserDefaults stream no longer exists")
                savedIndex = 0
            }
        }
        
        return savedIndex
    }
    
    func loadConfig() {
        isTransitioning = true
        buffer(true)
        streamData.getConfig()
    }
    
    func loadHLSData(){
        isTransitioning = true
        buffer(true)
        streamData.getHLSPath(streamData.streams[currentStreamIndex]["id"]!)
        
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
        
        buffer(false)
        isTransitioning = true
        isFirstPlay = true
    }
    
    func onRestart() {
        print("onRestart")
        loadConfig()
    }
    
    func onPause() {
        print("onPause")
    }
    
    func onUnpause() {
        print("onUnpause")
        
        if (streamController != nil) {
            if (streamController.player != nil) {
                onRestart()
            }
        }
    }
    
    func onDataError(notification: NSNotification) {
        let obj = notification.userInfo as! AnyObject
        let errorDomain = obj["error"] as! String
        
        onError(NSError(domain: errorDomain, code: 1, userInfo: nil))
    }
    
    func onStreamError(notification: NSNotification) {
        let obj = notification.userInfo as! AnyObject
        let error = obj["error"] as! NSError
        
        onError(error)
    }
    
    func onError(e: NSError) {
        switch e.domain {
            case "configDataError":
                print("! Config data error")
            case "hlsDataError":
                print("! HLS data error")
            case "playbackBufferEmpty":
                print("! Buffer empty")
            default:
                print("! Unknown stream error")
        }
        
        loadConfig()
    }
    
    func onConfigData(notification: NSNotification) {
        menu.streams = streamData.streams
        currentStreamIndex = getDefaultStreamIndex()
        loadHLSData()
    }
    
    func onHLSData(notification: NSNotification) {
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
            isFirstPlay = false
        } else {
            if (streamController != nil) {
                if (streamController.player != nil) {
                    streamController.player!.play()
                }
            }
        }
    }
    
    func onStreamVisible() {
        if (streamController != nil) {
            streamController.removeStaleViews(streamViewContainer)
        }
        
        isTransitioning = false
    }
    
    func onMenu(sender: UIGestureRecognizer) {
        // add menu
        self.view.addSubview(menu)
        
        // select current stream
        menu.select(streamData.streams[currentStreamIndex]["id"]!, animate: false)
        
        // re-enable default menu button behavior
        if (menuRecognizer != nil) {
            self.view.removeGestureRecognizer(menuRecognizer)
        }
    }
    
    func onSelect(sender: UIGestureRecognizer) {
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
                loadHLSData()
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
        
        menuRecognizer = UITapGestureRecognizer(target: self, action:#selector(ViewController.onMenu(_:)))
        
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
        
        if (streamData.streams.count < 2) {
            // no need for a menu
            return
        }
        
        // menu
        addMenuButtonInteraction()
        
        // tap
        let selectRecognizer = UITapGestureRecognizer(target: self, action:#selector(ViewController.onSelect(_:)))
        selectRecognizer.allowedPressTypes = [
            NSNumber(integer: UIPressType.PlayPause.rawValue),
            NSNumber(integer: UIPressType.Select.rawValue)
        ]
        self.view.addGestureRecognizer(selectRecognizer)
        
        // swipe
        let directions = [
            UISwipeGestureRecognizerDirection.Right,
            UISwipeGestureRecognizerDirection.Left,
            UISwipeGestureRecognizerDirection.Up,
            UISwipeGestureRecognizerDirection.Down
        ]
        
        for direction in directions {
            let swipeRecognizer = UISwipeGestureRecognizer(target: self, action:#selector(ViewController.onSwipe(_:)))
            swipeRecognizer.direction = direction
            self.view.addGestureRecognizer(swipeRecognizer)
        }
    }
    
    func addLogo() {
        let offset:CGFloat = 30
        let w:CGFloat = 220
        let h:CGFloat = 320
        
        let image = UIImage(named: "logo")
        logo = UIImageView(image: image!)
        
        placeLogo(w, h: h, offsetX: offset, offsetY: offset - 5)
    }
    
    func placeLogo(w: CGFloat, h: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        // place
        let bounds: CGRect = UIScreen.mainScreen().bounds
        logo.frame = CGRect(x: bounds.size.width - w - offsetX, y: offsetY, width: w, height: h)
        
        // fade in
        logo.alpha = 0
        
        UIView.animateWithDuration(0.8, delay: 3, options: .CurveEaseOut, animations: {
            self.logo.alpha = 0.5
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

