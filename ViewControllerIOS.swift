//
//  ViewControllerIOS.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/18/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit
import AVKit

class ViewControllerIOS: ViewController, UIGestureRecognizerDelegate {
    let maxNetworkErrors = 3
    var numNetworkErrors = 0
    var isAlerting = false
    var shadow: UIView!
    var donateButton: UIView!
    var currentAlert: UIAlertController!
    
    let donateStyleIndexKey = "donateStyleIndex"
    var donateStyle: [String : [String : String]]!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override func getBackgroundImage() -> CGImage {
        var asset = "iphonelarge"
        
        if let type = getDeviceType() {
            asset = type
        }
        
        return (UIImage(named: "bg" + asset)?.cgImage)!
    }
    
    override func addUI() {
        super.addUI()
        addDonateButton()
    }
    
    func getDonateStyleIndex() -> Int {
        var savedIndex = defaults.integer(forKey: donateStyleIndexKey)
        
        // integerForKey returns 0 if key not found
        if (savedIndex > 0) {
            print("NSUserDefaults donate style index retrieved: " + String(savedIndex))
            savedIndex -= 1
            
            if (savedIndex >= streamData.donateStyles.count) {
                print("NSUserDefaults donate style index no longer exists")
                savedIndex = 0
            }
        }
        
        // increment for next round
        if (savedIndex + 1 >= streamData.donateStyles.count) {
            defaults.set(1, forKey: donateStyleIndexKey)
        } else {
            defaults.set(savedIndex + 2, forKey: donateStyleIndexKey)
        }
        
        return savedIndex
    }
    
    func isIphoneX() -> Bool {
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            if (UIScreen.main.nativeBounds.height == 2436) {
                return true
            }
        }
        
        return false
    }
    
    func getAttributedString (_ string: String, _ font: String, _ size: CGFloat = 18) -> NSMutableAttributedString {
        let labelFont = UIFont(name: font, size: CGFloat(size))!
        let attributes = [NSAttributedStringKey.font: labelFont]
        
        return NSMutableAttributedString(string: string, attributes: attributes)
    }
    
    func addDonateButton() {
        let donateStyleIndex = getDonateStyleIndex()
        donateStyle = streamData.donateStyles[donateStyleIndex]
        
        donateButton = UIView()
        shadow = UIImageView(image: UIImage(named: "shadow")!)
        
        let screen = UIScreen.main.bounds
        
        // shadow
        let shadowW: CGFloat = 550
        let shadowH: CGFloat = 175
        shadow.frame = CGRect(x: 0, y: screen.height - shadowH, width: shadowW, height: shadowH)
        
        fadeIn(shadow, 0.8, 3.2)
        self.view.addSubview(shadow)
        
        // label
        let attributedString = getAttributedString(donateStyle["button"]!["normal"]!, "Whitney-Book")
        let boldString = getAttributedString(donateStyle["button"]!["bold"]!, "Whitney-Semibold")
        attributedString.append(boldString)
        
        let label = UILabel(frame: CGRect(x: 68, y: 79, width: 200, height: 21))
        label.textAlignment = .left
        label.textColor = UIColor.white
        label.attributedText = attributedString
        label.sizeToFit()
        
        donateButton.addSubview(label)
        
        // image
        let silhouette = UIImageView(image: UIImage(named: "silhouette")!)
        silhouette.alpha = 0.8
        donateButton.addSubview(silhouette)
        
        // place
        let w: CGFloat = 300
        let h: CGFloat = 100
        
        let yOffset: CGFloat = 8
        var xOffset: CGFloat = 12
        
        if (isIphoneX()) {
            xOffset += 4
        }
        
        donateButton.frame = CGRect(x: xOffset, y: screen.height - h - yOffset, width: w, height: h)
        
        addDonateButtonInteraction()
        fadeIn(donateButton, 0.5, 3.2)
        
        self.view.addSubview(donateButton)
    }
    
    func addDonateButtonInteraction() {
        donateButton.isUserInteractionEnabled = true
        
        let begin = UITouchBeginGestureRecognizer(target: self, action:#selector(self.onDonateTouchBegin(_:)))
        begin.delegate = self
        donateButton.addGestureRecognizer(begin)
        
        let end = UITouchEndGestureRecognizer(target: self, action:#selector(self.onDonateTouchEnd(_:)))
        donateButton.addGestureRecognizer(end)
    }
    
    @objc func onDonateTouchEnd(_ sender: UIGestureRecognizer) {
        donateButton.alpha = 0.5
        showDonateAlert()
    }
    
    @objc func onDonateTouchBegin(_ sender: UIGestureRecognizer) {
        donateButton.alpha = 1
    }
    
    override func removeUI() {
        super.removeUI()
        
        if (donateButton != nil) {
            donateButton.removeFromSuperview()
        }
        
        if (shadow != nil) {
            shadow.removeFromSuperview()
        }
        
        if (currentAlert != nil) {
            currentAlert.dismiss(animated: false, completion: nil)
            onAlertClose()
        }
    }
    
    override func addLogo() {
        let offset: CGFloat = 6
        
        var asset = "logoios"
        var w: CGFloat = 87
        var h: CGFloat = 135
        
        if (isIphoneX()) {
            asset = "logoioshoriz"
            w = 182
            h = 90
        }
        
        let image = UIImage(named: asset)
        logo = UIImageView(image: image!)
        logo.isUserInteractionEnabled = true
        
        let begin = UITouchBeginGestureRecognizer(target: self, action:#selector(self.onLogoTouchBegin(_:)))
        begin.delegate = self
        logo.addGestureRecognizer(begin)
        
        let end = UITouchEndGestureRecognizer(target: self, action:#selector(self.onLogoTouchEnd(_:)))
        logo.addGestureRecognizer(end)
        
        placeLogo(w, h: h, offsetX: offset, offsetY: offset - 1)
    }
    
    @objc func onLogoTouchEnd(_ sender: UIGestureRecognizer) {
        logo.alpha = 0.5
        showLogoAlert()
    }
    
    @objc func onLogoTouchBegin(_ sender: UIGestureRecognizer) {
        logo.alpha = 1
    }
    
    override func onStreamPlay() {
        super.onStreamPlay()
        numNetworkErrors = 0
    }
    
    override func onError(_ e: NSError) {
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
        
        numNetworkErrors += 1
        
        if (numNetworkErrors < maxNetworkErrors) {
            // retry
            loadConfig()
        } else {
            // alert
            showErrorAlert()
        }
    }
    
    func requestAlert() -> Bool {
        if (isAlerting) {
            return false
        }
        
        // close menu
        if (menu.onStage) {
            onSelect()
        }
        
        isAlerting = true
        return true
    }
    
    func onAlertClose() {
        isAlerting = false
        currentAlert = nil
    }
    
    func getCustomAlertController(_ title: String, _ message: String) -> UIAlertController {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        let title = getAttributedString(title, "Whitney-Semibold", 18)
        alert.setValue(title, forKey: "attributedTitle")
        
        let message = getAttributedString(message, "Whitney-Book", 16)
        alert.setValue(message, forKey: "attributedMessage")
        
        return alert
    }
    
    func goToWebsite(_ url: String) {
        UIApplication.shared.openURL(URL(string: url)!)
    }
    
    func playFallbackVideo() {
        let videoURL = Bundle.main.url(forResource: "fallback", withExtension: "mp4")!
        loadAndPlay(url: videoURL.absoluteString, isFlat: true)
    }
    
    func showUrlAlert(_ alertKey: String) {
        if (!requestAlert()) {
            return
        }
        
        var config: [String: String] = streamData.alerts[alertKey]!
        
        if (alertKey == "donate") {
            config = donateStyle["alert"]!
        }
        
        currentAlert = getCustomAlertController(config["title"]!, config["body"]!)
        
        currentAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.onAlertClose()
        }))
        
        currentAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.goToWebsite(config["url"]!)
            self.onAlertClose()
        }))
        
        // show the alert
        self.present(currentAlert, animated: true, completion: nil)
    }
    
    func showFallbackAlert(_ alertKey: String) {
        if (!requestAlert()) {
            return
        }
        
        numNetworkErrors = 0
        
        let config: [String: String] = streamData.alerts[alertKey]!
        currentAlert = getCustomAlertController(config["title"]!, config["body"]!)
        
        currentAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.loadConfig()
            self.onAlertClose()
        }))
        
        currentAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.playFallbackVideo()
            self.onAlertClose()
        }))
        
        // show the alert
        self.present(currentAlert, animated: true, completion: nil)
    }
    
    func showLogoAlert() {
        showUrlAlert("logo")
    }
    
    func showDonateAlert() {
        showUrlAlert("donate")
    }
    
    func showErrorAlert() {
        showFallbackAlert("error")
    }
    
    override func onFlatComplete() {
        showFallbackAlert("flatPlaybackComplete")
    }
    
    @objc func onTouchBegin(_ sender: UIGestureRecognizer) {
        let btn = sender.view as! SwitchButton
        // print("onTouchBegin: " + btn.id)
        
        btn.isBeingPressed = true
        
        btn.activate(true)
        
        // deactivate other btns
        for otherBtn in menu.buttons {
            if (otherBtn.id != btn.id) {
                otherBtn.deactivate(true)
            }
        }
    }
    
    @objc func onTouchEnd(_ sender: UIGestureRecognizer) {
        let btn = sender.view as! SwitchButton
        // print("onTouchEnd: " + btn.id)
        
        if (!btn.isBeingPressed) {
            return
        }
        
        btn.isBeingPressed = false
        menu.select(btn.id, animate: false)
        onSelect(sender)
    }
    
    override func addInteraction() {
        // remove any pre-existing recognizers
        if (self.view.gestureRecognizers != nil) {
            for recognizer in self.view.gestureRecognizers! {
                self.view.removeGestureRecognizer(recognizer)
            }
        }
        
        if (menu.buttons == nil) {
            return
        }
        
        for btn in menu.buttons {
            if (btn.gestureRecognizers != nil) {
                for recognizer in btn.gestureRecognizers! {
                    btn.removeGestureRecognizer(recognizer)
                }
            }
        }
        
        if (streamData.streams.count < 2) {
            // no need for a menu
            return
        }
        
        // tap to open menu
        let selectRecognizer = UITapGestureRecognizer(target: self, action:#selector(self.onSelect(_:)))
        self.view.addGestureRecognizer(selectRecognizer)
    }
    
    override func onMenu(_ sender: UIGestureRecognizer! = nil) {
        super.onMenu(sender)
        
        if (menu.buttons == nil) {
            return
        }
        
        // gesture recognizers
        for btn in menu.buttons {
            // remove
            if (btn.gestureRecognizers != nil) {
                for recognizer in btn.gestureRecognizers! {
                    btn.removeGestureRecognizer(recognizer)
                }
            }
            
            // add
            let begin = UITouchBeginGestureRecognizer(target: self, action:#selector(self.onTouchBegin(_:)))
            begin.delegate = self
            btn.addGestureRecognizer(begin)
            
            let end = UITouchEndGestureRecognizer(target: self, action:#selector(self.onTouchEnd(_:)))
            btn.addGestureRecognizer(end)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
