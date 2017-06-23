//
//  StreamData.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/28/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class StreamData: NSObject {
    fileprivate let _configEndpoint: String = "http://s3.amazonaws.com/data.calacademy.org/sharks/data.json"
    fileprivate var _endpoint: String!
    fileprivate var _hlsKey: String!
    fileprivate var _task: URLSessionDataTask!
    fileprivate var _session: URLSession!
    
    var streams: [[String:String]]!
    
    // defaults
    var donateButton: [String: String] = [
        "normal": "feed ",
        "bold": "the Chondrichthyes"
    ]
    
    var alerts: [String: [String: String]] = [
        "logo": [
            "title": "Visit Us Online",
            "body": "Learn about events and exhibits, purchase tickets, submit feedback, and more!",
            "url": "http://www.calacademy.org"
        ],
        "donate": [
            "title": "Help Advance Our Mission",
            "body": "Please visit our website to make a donation.",
            "url": "http://www.calacademy.org/donate"
        ],
        "error": [
            "title": "Network Error",
            "body": "There appears to be a problem with the network. Would you like to watch a pre-recorded video instead?"
        ],
        "flatPlaybackComplete": [
            "title": "Playback Complete",
            "body": "Would you like to watch the video again?"
        ]
    ]
    
    func getHLSPath(_ id: String) {
        destroy()
        _session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        
        let url = URL(string: _endpoint + "=" + id)!
        
        _task = _session.dataTask(with: url, completionHandler: {
            data, response, error -> Void in
            
            DispatchQueue.main.async {
                self._onHLSPathComplete(data, response: response, error: error as NSError?)
            }
            
            return
        })
        
        _task.resume()
    }
    
    func getConfig() {
        destroy()
        _session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        
        let url = URL(string: _configEndpoint)!
        
        _task = _session.dataTask(with: url, completionHandler: {
            data, response, error -> Void in
            
            DispatchQueue.main.async {
                self._onConfigComplete(data, response: response, error: error as NSError?)
            }
            
            return
        })
        
        _task.resume()
    }
    
    fileprivate func _onConfigComplete(_ data: Data?, response: URLResponse?, error: NSError?) {
        let errorInfo = [
            "error": "configDataError"
        ]
        
        if (error != nil) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "dataError"), object: nil, userInfo: errorInfo)
            return
        }
        
        print("config loaded from " + (response!.url?.absoluteString)!)
        
        let json = JSON(data: data!)
        
        // donate button
        if let donateButtonData = json["donateButton"].dictionary {
            for (key, _) in donateButton {
                if let newValue = donateButtonData[key]?.string {
                    donateButton[key] = newValue
                }
            }
        }
        
        // alerts
        if let alertsData = json["alerts"].dictionary {
            for (key, originalAlert) in alerts {
                if let newAlert = alertsData[key]?.dictionary {
                    for (alertKey, _) in originalAlert {
                        if let newValue = newAlert[alertKey]?.string {
                            alerts[key]?[alertKey] = newValue
                        }
                    }
                }
            }
        }
        
        // stream
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
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "configDataLoaded"), object: nil)
                        return
                    }
                }
            }
        }
        
        // stream data not found
        NotificationCenter.default.post(name: Notification.Name(rawValue: "dataError"), object: nil, userInfo: errorInfo)
    }
    
    fileprivate func _onHLSPathComplete(_ data: Data?, response: URLResponse?, error: NSError?) {
        let errorInfo = [
            "error": "hlsDataError"
        ]
        
        if (error != nil) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "dataError"), object: nil, userInfo: errorInfo)
            return
        }
        
        print("HLS data loaded from " + (response!.url?.absoluteString)!)
        
        // split data from YouTube
        let datastring = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        let arr = datastring?.components(separatedBy: "&") as Array!
        
        // search for "hlsvp"
        for part in arr! {
            var varArr = part.components(separatedBy: "=")
            
            if (varArr[0] == _hlsKey) {
                // found video url, broadcast to observers
                let foo = varArr[1]
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "hlsDataLoaded"), object: nil, userInfo: [
                    "url": foo.removingPercentEncoding!
                ])
                
                return
            }
        }
        
        // stream data not found
        NotificationCenter.default.post(name: Notification.Name(rawValue: "dataError"), object: nil, userInfo: errorInfo)
    }
    
    func destroy() {
        if (_task != nil) {
            _task.cancel()
        }
        
        if (_session != nil) {
            _session.invalidateAndCancel()
        }
    }
}
