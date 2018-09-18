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
    var slug = "unknown"
    
    // add logo and interaction once only
    var isFirstPlay = true
    
    // prevent crazy clicks
    var isTransitioning = true
    
    var buffering = Buffering(image: nil)
    var currentStreamIndex = 0
    var menuRecognizer:UIGestureRecognizer!
    
    let delaySecs:Double = 1.0
    let currentStreamIndexDefaultsKey = "currentStreamIndex"
    var defaults = UserDefaults.standard
    
    var logo:UIImageView!
    var logoShadow:UIImageView!
    var streamViewContainer = UIView()
    
    var menu = SwitchMenu()
    var streamData = StreamData()
    var streamController:StreamController!
    var lastStreamController:StreamController!
    
    internal var _pollFadeOutLastStream:Timer!
    
    override func viewDidLoad() {
        let device = getDeviceType() ?? "unknown"
        print("device type: " + device)
        
        if let mySlug = Bundle.main.infoDictionary?["StreamSlug"] as? String {
            slug = mySlug
        }
        
        streamData.slug = slug
        buffering.delaySecs = self.delaySecs
        
        self.view.backgroundColor = UIColor(white: 1, alpha: 0)
        self.view.layer.contents = getBackgroundImage()
        
        super.viewDidLoad()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(ViewController.onStreamPlay), name:NSNotification.Name(rawValue: "streamPlaying"), object: nil)
        nc.addObserver(self, selector: #selector(ViewController.onFlatComplete), name:NSNotification.Name(rawValue: "flatComplete"), object: nil)
        nc.addObserver(self, selector: #selector(ViewController.onStreamVisible), name:NSNotification.Name(rawValue: "streamVisible"), object: nil)
        nc.addObserver(self, selector: #selector(ViewController.onStreamError(_:)), name:NSNotification.Name(rawValue: "streamError"), object: nil)
        nc.addObserver(self, selector: #selector(ViewController.onDataError(_:)), name:NSNotification.Name(rawValue: "dataError"), object: nil)
        nc.addObserver(self, selector: #selector(ViewController.onConfigData(_:)), name:NSNotification.Name(rawValue: "configDataLoaded"), object: nil)
        nc.addObserver(self, selector: #selector(ViewController.onHLSData(_:)), name:NSNotification.Name(rawValue: "hlsDataLoaded"), object: nil)
        
        self.view.addSubview(streamViewContainer)
        loadConfig()
    }
    
    func getBackgroundImage() -> CGImage {
        return (UIImage(named: "bg")?.cgImage)!
    }
    
    func getDeviceType() -> String? {
        let screen = UIScreen.main.nativeBounds
        
        // Apple TV
        if (UIDevice.current.userInterfaceIdiom == .tv) {
            return "tv"
        }
        
        // iPad
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            switch (screen.height) {
                case 2048:
                    return "ipadsmall"
                case 2224:
                    return "ipadmedium"
                case 2732:
                    return "ipadlarge"
                default:
                    return nil
            }
        }
        
        // iPhone
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            switch (screen.height) {
                case 1136:
                    return "iphonesmall"
                case 1334:
                    return "iphonemedium"
                case 2208:
                    return "iphonelarge"
                case 1792:
                    return "iphonexr"
                case 2436:
                    return "iphonex"
                case 2688:
                    return "iphonexsmax"
                default:
                    return nil
            }
        }

        return nil
    }
    
    func getDefaultStreamIndex() -> Int {
        var savedIndex = defaults.integer(forKey: currentStreamIndexDefaultsKey)
        
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
        defaults.set(currentStreamIndex + 1, forKey: currentStreamIndexDefaultsKey)
    }
    
    func onExit() {
        print("onExit")
        
        streamData.destroy()
        
        // destroy stream
        if (streamController != nil) {
            streamController.destroyAndRemove()
            streamController = nil
        }
        
        if (lastStreamController != nil) {
            lastStreamController.destroyVolumeTimer()
            lastStreamController = nil
        }
        
        if (_pollFadeOutLastStream != nil) {
            _pollFadeOutLastStream.invalidate()
        }
        
        removeUI()
        
        buffer(false)
        isTransitioning = true
        isFirstPlay = true
    }
    
    func removeUI() {
        if (logoShadow != nil) {
            logoShadow.removeFromSuperview()
        }
        
        if (logo != nil) {
            logo.removeFromSuperview()
        }
        
        menu.removeFromSuperview()
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
    
    @objc func onDataError(_ notification: Notification) {
        let obj = (notification as NSNotification).userInfo as AnyObject
        let errorDomain = obj["error"] as! String
        
        onError(NSError(domain: errorDomain, code: 1, userInfo: nil))
    }
    
    @objc func onStreamError(_ notification: Notification) {
        let obj = (notification as NSNotification).userInfo as AnyObject
        let error = obj["error"] as! NSError
        
        onError(error)
    }
    
    @objc func onFlatComplete() {
    }
    
    func onError(_ e: NSError) {
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
    
    @objc func onConfigData(_ notification: Notification) {
        menu.streams = streamData.streams
        currentStreamIndex = getDefaultStreamIndex()
        loadHLSData()
    }
    
    @objc func onHLSData(_ notification: Notification) {
        let obj = (notification as NSNotification).userInfo as! [String:AnyObject]
        let url = obj["url"] as! String
        
        loadAndPlay(url: url)
    }
    
    func loadAndPlay(url: String, isFlat: Bool = false) {
        if (streamController != nil) {
            lastStreamController = streamController
            streamController.destroy()
        }
        
        // let testUrl = "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
        
        streamController = StreamController()
        streamController.delaySecs = self.delaySecs
        streamController.aspect = ["width": CGFloat(truncating: streamData.width), "height": CGFloat(truncating: streamData.height)]
        streamController.setStream(url, minSecs: streamData.minSecs, isFlat: isFlat)
    }
    
    @objc func onStreamPlay() {
        buffer(false)
        streamController.addToView(streamViewContainer)
        
        if (isFirstPlay) {
            addUI()
            addInteraction()
            isFirstPlay = false
        } else {
            if (streamController != nil) {
                if (streamController.player != nil) {
                    streamController.player!.play()
                }
            }
            
            if (_pollFadeOutLastStream != nil) {
                _pollFadeOutLastStream.invalidate()
            }
            
            _pollFadeOutLastStream = Timer.scheduledTimer(timeInterval: self.delaySecs - 0.5, target: self, selector: #selector(ViewController.fadeOutLastStream), userInfo: nil, repeats: false)
        }
    }
    
    @objc func fadeOutLastStream() {
        if (lastStreamController != nil) {
            lastStreamController.fadeVolume(fadeIn: false)
        }
    }
    
    @objc func onStreamVisible() {
        if (streamController != nil) {
            streamController.removeStaleViews(streamViewContainer)
        }
        
        var opacity:CGFloat = 0
        var scale:CGFloat = 1.0
        
        if (streamData.streams == nil || streamData.streams.count < (currentStreamIndex + 1)) {
            alterLogoShadow(opacity: opacity, scale: scale)
            isTransitioning = false
            return
        }
        
        let selectedStream = streamData.streams[currentStreamIndex]
        
        if let logoShadowOpacity = selectedStream["logoShadowOpacity"] {
            if let n = NumberFormatter().number(from: logoShadowOpacity) {
                opacity = CGFloat(truncating: n)
            }
        }
        
        if let logoShadowScale = selectedStream["logoShadowScale"] {
            if let n = NumberFormatter().number(from: logoShadowScale) {
                scale = CGFloat(truncating: n)
            }
        }
        
        if (getDeviceType() == "tv") {
            if let logoShadowOpacity = selectedStream["logoShadowOpacityTV"] {
                if let n = NumberFormatter().number(from: logoShadowOpacity) {
                    opacity = CGFloat(truncating: n)
                }
            }
            
            if let logoShadowScale = selectedStream["logoShadowScaleTV"] {
                if let n = NumberFormatter().number(from: logoShadowScale) {
                    scale = CGFloat(truncating: n)
                }
            }
        }
        
        alterLogoShadow(opacity: opacity, scale: scale)
        isTransitioning = false
    }
    
    @objc func onMenu(_ sender: UIGestureRecognizer! = nil) {
        // add menu
        self.view.addSubview(menu)
        
        // select current stream
        menu.select(streamData.streams[currentStreamIndex]["id"]!, animate: false)
        
        // re-enable default menu button behavior
        if (menuRecognizer != nil) {
            self.view.removeGestureRecognizer(menuRecognizer)
        }
    }
    
    @objc func onSelect(_ sender: UIGestureRecognizer! = nil) {
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
    
    @objc func onSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
            case UISwipeGestureRecognizerDirection.left,
            UISwipeGestureRecognizerDirection.down:
                menu.navigate("left")
            case UISwipeGestureRecognizerDirection.right,
            UISwipeGestureRecognizerDirection.up:
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
            NSNumber(value: UIPressType.menu.rawValue as Int)
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
            NSNumber(value: UIPressType.playPause.rawValue as Int),
            NSNumber(value: UIPressType.select.rawValue as Int)
        ]
        self.view.addGestureRecognizer(selectRecognizer)
        
        // swipe
        let directions = [
            UISwipeGestureRecognizerDirection.right,
            UISwipeGestureRecognizerDirection.left,
            UISwipeGestureRecognizerDirection.up,
            UISwipeGestureRecognizerDirection.down
        ]
        
        for direction in directions {
            let swipeRecognizer = UISwipeGestureRecognizer(target: self, action:#selector(ViewController.onSwipe(_:)))
            swipeRecognizer.direction = direction
            self.view.addGestureRecognizer(swipeRecognizer)
        }
    }
    
    func addUI() {
        addLogoShadow()
        addLogo()
    }
    
    func addLogoShadow() {
        let image = UIImage(named: "logoshadow")
        logoShadow = UIImageView(image: image!)
        logoShadow.alpha = 0
        
        placeLogo(300, h: 300, offsetX: 0, offsetY: 0, targetOpacity: 0, theLogo: logoShadow)
        setAnchorPoint(anchorPoint: CGPoint(x: 1, y: 0), forView: logoShadow)
    }
    
    func addLogo() {
        let offset:CGFloat = 30
        let w:CGFloat = 220
        let h:CGFloat = 320
        
        let image = UIImage(named: "logo")
        logo = UIImageView(image: image!)
        
        placeLogo(w, h: h, offsetX: offset, offsetY: offset - 5)
    }
    
    func fadeIn(_ view: UIView, _ targetAlpha: CGFloat, _ delay: Double, _ onComplete: ((Bool) -> Void)? = nil) {
        // fade in
        view.alpha = 0
        
        UIView.animate(withDuration: 0.8, delay: delay, options: .curveEaseOut, animations: {
            view.alpha = targetAlpha
        }, completion: onComplete)
    }
    
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
    
    func alterLogoShadow(opacity: CGFloat, scale: CGFloat) {
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut, animations: {
            self.logoShadow.alpha = opacity
            self.logoShadow.transform = CGAffineTransform(scaleX: scale, y: scale)
        })
    }
    
    func placeLogo(_ w: CGFloat, h: CGFloat, offsetX: CGFloat, offsetY: CGFloat, targetOpacity: CGFloat = 0.5, theLogo: UIImageView? = nil) {
        let theLogo = theLogo ?? self.logo
        
        // place
        let bounds: CGRect = UIScreen.main.bounds
        theLogo!.frame = CGRect(x: bounds.size.width - w - offsetX, y: offsetY, width: w, height: h)
        
        fadeIn(theLogo!, targetOpacity, self.delaySecs + 0.5)
        
        // add to stage
        self.view.addSubview(theLogo!)
    }
    
    func buffer(_ boo: Bool) {
        if (buffering.onStage == boo) {
            return
        }
        
        buffering.show(boo, view: self.view)
    }
}

