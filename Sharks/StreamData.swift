//
//  StreamData.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/28/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class StreamData: NSObject {
    private let _configEndpoint = "http://s3.amazonaws.com/data.calacademy.org/sharks/data.json"
    private var _endpoint:String!
    private var _hlsKey:String!
    private var _task:NSURLSessionDataTask!
    private var _session:NSURLSession!
    
    var streams:[[String:String]]!
    
    func getHLSPath(id: String) {
        destroy()
        _session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        
        let url = NSURL(string: _endpoint + "=" + id)!
        
        _task = _session.dataTaskWithURL(url, completionHandler: {
            data, response, error -> Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                self._onHLSPathComplete(data, response: response, error: error)
            }
        })
        
        _task.resume()
    }
    
    func getConfig() {
        destroy()
        _session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        
        let url = NSURL(string: _configEndpoint)!
        
        _task = _session.dataTaskWithURL(url, completionHandler: {
            data, response, error -> Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                self._onConfigComplete(data, response: response, error: error)
            }
        })
        
        _task.resume()
    }
    
    private func _onConfigComplete(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let errorInfo = [
            "error": "configDataError"
        ]
        
        if (error != nil) {
            NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil, userInfo: errorInfo)
            return
        }
        
        print("config loaded from " + (response!.URL?.absoluteString)!)
        
        let json = JSON(data: data!)

        if let endpoint = json["endpoint"].string {
            _endpoint = endpoint
            
            if let key = json["key"].string {
                _hlsKey = key
                
                if let myStreams = json["streams"].array {
                    if (myStreams.count > 0) {
                        streams = [[String:String]]()
                        
                        // success
                        for stream in myStreams {
                            streams.append([
                                "id": stream["id"].string!,
                                "label": stream["label"].string!,
                                "asset": stream["asset"].string!
                            ])
                        }
                        
                        NSNotificationCenter.defaultCenter().postNotificationName("configDataLoaded", object: nil)
                        return
                    }
                }
            }
        }
        
        // stream data not found
        NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil, userInfo: errorInfo)
    }
    
    private func _onHLSPathComplete(data: NSData?, response: NSURLResponse?, error: NSError?) {
        let errorInfo = [
            "error": "hlsDataError"
        ]
        
        if (error != nil) {
            NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil, userInfo: errorInfo)
            return
        }
        
        print("HLS data loaded from " + (response!.URL?.absoluteString)!)
        
        // split data from YouTube
        let datastring = NSString(data: data!, encoding: NSUTF8StringEncoding)
        let arr = datastring?.componentsSeparatedByString("&") as Array!
        
        // search for "hlsvp"
        for part in arr {
            var varArr = part.componentsSeparatedByString("=")
            
            if (varArr[0] == _hlsKey) {
                // found video url, broadcast to observers
                let foo = varArr[1]
                
                NSNotificationCenter.defaultCenter().postNotificationName("hlsDataLoaded", object: nil, userInfo: [
                    "url": foo.stringByRemovingPercentEncoding!
                ])
                
                return
            }
        }
        
        // stream data not found
        NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil, userInfo: errorInfo)
    }
    
    func destroy() {
        if (_session != nil) {
            _session.invalidateAndCancel()
        }
    }
}
