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
    var shadow:UIView!
    var donateButton:UIView!
    
    override func addUI() {
        super.addUI()
        addDonateButton()
    }
    
    func getAttributedString (_ string: String, _ font: String, _ size: CGFloat = 18) -> NSMutableAttributedString {
        let labelFont = UIFont(name: font, size: CGFloat(size))!
        let attributes = [NSFontAttributeName: labelFont]
        
        return NSMutableAttributedString(string: string, attributes: attributes)
    }
    
    func addDonateButton() {
        donateButton = UIView()
        shadow = UIImageView(image: UIImage(named: "shadow")!)
        
        let screen = UIScreen.main.bounds
        
        // shadow
        let shadowW:CGFloat = 550
        let shadowH:CGFloat = 175
        shadow.frame = CGRect(x: 0, y: screen.height - shadowH, width: shadowW, height: shadowH)
        
        fadeIn(shadow, 0.7, 3.6)
        self.view.addSubview(shadow)
        
        // label
        let attributedString = getAttributedString("feed ", "Whitney-Book")
        let boldString = getAttributedString("the Chondrichthyes", "Whitney-Semibold")
        attributedString.append(boldString)
        
        let label = UILabel(frame: CGRect(x: 80, y: 52, width: 200, height: 21))
        label.textAlignment = .left
        label.textColor = UIColor.white
        label.attributedText = attributedString
        label.sizeToFit()
        
        donateButton.addSubview(label)
        
        // image
        let silhouette = UIImageView(image: UIImage(named: "silhouette")!)
        donateButton.addSubview(silhouette)
        
        // place
        let offset:CGFloat = 4
        let w:CGFloat = 250
        let h:CGFloat = 76
        donateButton.frame = CGRect(x: offset, y: screen.height - h - offset, width: w, height: h)
        
        addDonateButtonInteraction()
        fadeIn(donateButton, 0.6, 3.6)
        
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
    
    func onDonateTouchEnd(_ sender: UIGestureRecognizer) {
        donateButton.alpha = 0.6
        showDonateAlert()
    }
    
    func onDonateTouchBegin(_ sender: UIGestureRecognizer) {
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
    }
    
    override func addLogo() {
        let offset:CGFloat = 6
        let w:CGFloat = 87
        let h:CGFloat = 135
        
        let image = UIImage(named: "logoios")
        logo = UIImageView(image: image!)
        logo.isUserInteractionEnabled = true
        
        let begin = UITouchBeginGestureRecognizer(target: self, action:#selector(self.onLogoTouchBegin(_:)))
        begin.delegate = self
        logo.addGestureRecognizer(begin)
        
        let end = UITouchEndGestureRecognizer(target: self, action:#selector(self.onLogoTouchEnd(_:)))
        logo.addGestureRecognizer(end)
        
        placeLogo(w, h: h, offsetX: offset, offsetY: offset - 1)
    }
    
    func onLogoTouchEnd(_ sender: UIGestureRecognizer) {
        logo.alpha = 0.5
        showLogoAlert()
    }
    
    func onLogoTouchBegin(_ sender: UIGestureRecognizer) {
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
    }
    
    func showLogoAlert() {
        if (!requestAlert()) {
            return
        }
        
        let alert = UIAlertController(title: "Visit Us Online", message: "Learn about events and exhibits, purchase tickets, submit feedback, and more!", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.onAlertClose()
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.goToWebsite("http://www.calacademy.org/explore-science/sharks-live-for-apple-tv")
            self.onAlertClose()
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDonateAlert() {
        if (!requestAlert()) {
            return
        }
        
        let alert = UIAlertController(title: "Help Advance Our Mission", message: "Please visit our website to make a donation.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.onAlertClose()
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.goToWebsite("http://www.calacademy.org/donate")
            self.onAlertClose()
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    override func onFlatComplete() {
        if (!requestAlert()) {
            return
        }
        
        let alert = UIAlertController(title: "Playback Complete", message: "Would you like to watch the video again?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.loadConfig()
            self.onAlertClose()
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.playFallbackVideo()
            self.onAlertClose()
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert() {
        if (!requestAlert()) {
            return
        }
        
        numNetworkErrors = 0
        
        let alert = UIAlertController(title: "Network Error", message: "There appears to be a problem with the network. Would you like to watch a pre-recorded video instead?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.loadConfig()
            self.onAlertClose()
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.playFallbackVideo()
            self.onAlertClose()
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func goToWebsite(_ url: String) {
        UIApplication.shared.openURL(URL(string: url)!)
    }
    
    func playFallbackVideo() {
        // @todo
        // shark video
        let videoURL = Bundle.main.url(forResource: "penguins-3k-h264", withExtension: "mp4")!
        loadAndPlay(url: videoURL.absoluteString)
    }
    
    func onTouchBegin(_ sender: UIGestureRecognizer) {
        let btn = sender.view as! SwitchButton
        btn.isBeingPressed = true
        
        btn.activate(true)
        
        // deactivate other btns
        for otherBtn in menu.buttons {
            if (otherBtn.id != btn.id) {
                otherBtn.deactivate(true)
            }
        }
    }
    
    func onTouchEnd(_ sender: UIGestureRecognizer) {
        let btn = sender.view as! SwitchButton
        
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
        
        // add gestures to menu items
        for btn in menu.buttons {
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

