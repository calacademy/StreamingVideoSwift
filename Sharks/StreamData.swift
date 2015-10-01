//
//  StreamData.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/28/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class StreamData: NSObject {
    private var _endpoint = "https://youtube.com/get_video_info?video_id"
    private var _session = NSURLSession.sharedSession()
    private var _task:NSURLSessionDataTask!
    
    func connect(id: String) {
        destroy()
        let url = NSURL(string: _endpoint + "=" + id)!
        
        _task = _session.dataTaskWithURL(url, completionHandler: {
            data, response, error -> Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                self._onComplete(data, response: response, error: error)
            }
        })
        
        _task.resume()
    }
    
    private func _onComplete(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if (error != nil) {
            NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil)
            return
        }
        
        print("data loaded from " + (response!.URL?.absoluteString)!)
        
        // split data from YouTube
        let datastring = NSString(data: data!, encoding: NSUTF8StringEncoding)
        let arr = datastring?.componentsSeparatedByString("&") as Array!
        
        // search for "hlsvp"
        for part in arr {
            var varArr = part.componentsSeparatedByString("=")
            
            if (varArr[0] == "hlsvp") {
                // found video url, broadcast to observers
                let foo = varArr[1]
                
                NSNotificationCenter.defaultCenter().postNotificationName("dataLoaded", object: nil, userInfo: [
                    "url": foo.stringByRemovingPercentEncoding!
                ])
                
                return
            }
        }
        
        // stream data not found
        NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil)
    }
    
    func destroy() {
        _session.invalidateAndCancel()
    }
}
