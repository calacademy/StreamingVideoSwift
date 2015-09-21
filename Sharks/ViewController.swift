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
    var data = NSMutableData()
    var moviePlayer:AVPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // lagoon
        // loadYouTubeData("TStjLJIc3DY")
        
        // reef
        loadYouTubeData("jyWHDIECRYQ")
    }
    
    func loadYouTubeData(id: String){
        let urlPath = "https://youtube.com/get_video_info?video_id=" + id
        let url = NSURL(string: urlPath)!
        let request = NSURLRequest(URL: url)
        
        _ = NSURLConnection(request: request, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        self.data.appendData(data)
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
    
    func tapped(sender: UITapGestureRecognizer) {
        print("tapped")
    }
    
    func swiped(sender: UISwipeGestureRecognizer) {
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
        // tap
        let tapRecognizer = UITapGestureRecognizer(target: self, action:"tapped:")
        self.view.addGestureRecognizer(tapRecognizer)
        
        // swipe
        let directions = [UISwipeGestureRecognizerDirection.Right, UISwipeGestureRecognizerDirection.Left, UISwipeGestureRecognizerDirection.Up, UISwipeGestureRecognizerDirection.Down];
        
        for direction in directions {
            let swipeRecognizer = UISwipeGestureRecognizer(target: self, action:"swiped:")
            swipeRecognizer.direction = direction
            self.view.addGestureRecognizer(swipeRecognizer)
        }
    }
    
    func addLogo() {
        let w:CGFloat = 220
        let h:CGFloat = 320
        
        let imageName = "logo.png"
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        
        // place
        let bounds: CGRect = UIScreen.mainScreen().bounds
        imageView.frame = CGRect(x: bounds.size.width - w, y: 0, width: w, height: h)
        
        // fade in
        imageView.alpha = 0
        
        UIView.animateWithDuration(1, delay: 2, options: .CurveEaseOut, animations: {
            imageView.alpha = 0.65
        }, completion: nil)
        
        // add to stage
        self.view.addSubview(imageView)
    }
    
    func onPlay() {
        // ReadyToPlay fires multiple times for unknown reasons
        if (isPlaying) {
            return
        }
        
        isPlaying = true
        
        // size
        let bounds: CGRect = UIScreen.mainScreen().bounds
        let w:CGFloat = bounds.size.width
        let h:CGFloat = bounds.size.height
        moviePlayer.view.frame = CGRect(x: 0, y: 0, width: w, height: h)
        
        // fade in
        moviePlayer.view.alpha = 0;
        
        UIView.animateWithDuration(1, delay: 1, options: .CurveEaseOut, animations: {
            self.moviePlayer.view.alpha = 1
        }, completion: nil)
        
        self.view.addSubview(moviePlayer.view)
        
        addLogo()
        addInteraction()
    }
    
    func onError(e: NSError) {
        print("error!")
        print(e)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let stream = moviePlayer.player!.currentItem!
        
        switch stream.status {
            case .Unknown:
                if (stream.error != nil) {
                    onError(stream.error!)
                }
            case .Failed:
                onError(stream.error!)
            case .ReadyToPlay:
                onPlay()
        }
    }
    
    func displayVideo(path: String) {
        let url:NSURL = NSURL(string: path)!
        let player = AVPlayer(URL: url)
        
        moviePlayer = AVPlayerViewController()
        moviePlayer.player = player;
        moviePlayer.showsPlaybackControls = false;
        moviePlayer.player!.currentItem!.addObserver(self, forKeyPath:"status", options:.Initial, context:nil)

        player.volume = 0
        player.play()
    }
}

