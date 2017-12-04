//
//  SpriteView.swift
//  Stringrays Live
//
//  Created by Rotter, Greg on 12/1/17.
//  Copyright © 2017 Greg Rotter. All rights reserved.
//

import UIKit

class SpriteView: UIView {
    fileprivate var _sheet:UIImageView!
    fileprivate var _numFrames:Int!
    fileprivate var _w:Int!
    fileprivate var _h:Int!
    fileprivate var _pollAnimate:Timer!
    fileprivate var _pollAnimateCycle:Timer!
    fileprivate var _currentFrame:Int = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        self.layer.masksToBounds = true
    }
    
    func setSheet(sheetName: String, frameWidth: Int, frameHeight: Int, numFrames: Int) {
        _w = frameWidth
        _h = frameHeight
        _numFrames = numFrames
        
        self.frame = CGRect(x: 0, y: 0, width: _w / 2, height: _h / 2)
        
        _sheet = UIImageView(image: UIImage(named: sheetName))
        self.addSubview(_sheet)
    }
    
    func goToFrame(_ frame: Int) {
        let targetY = (frame - 1) * _h * -1
        _sheet.frame = CGRect(x: 0, y: targetY, width: _w, height: _h * _numFrames)
    }
    
    @objc private func _incrementFrames() {
       _currentFrame += 1
        
        if (_currentFrame > _numFrames) {
            _currentFrame = 1
        }
        
        goToFrame(_currentFrame)
        
        if (_currentFrame == 1) {
            _pollAnimate.invalidate()
        }
    }
    
    func animate() {
        _incrementFrames()
        
        if (_pollAnimate != nil) {
            _pollAnimate.invalidate()
        }
        
        _pollAnimate = Timer.scheduledTimer(timeInterval: 0.06, target: self, selector: #selector(SpriteView._incrementFrames), userInfo: nil, repeats: true)
    }
    
    @objc func cycle() {
        self.animate()
        
        if (_pollAnimateCycle != nil) {
            _pollAnimateCycle.invalidate()
        }
        
        let delay = Double(CGFloat.random(min: 15, max: 30))
        _pollAnimateCycle = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(SpriteView.cycle), userInfo: nil, repeats: false)
    }
    
    func destroy() {
        if (_pollAnimateCycle != nil) {
            _pollAnimateCycle.invalidate()
        }
        
        if (_pollAnimate != nil) {
            _pollAnimate.invalidate()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
