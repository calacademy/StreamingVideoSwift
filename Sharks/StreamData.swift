//
//  StreamData.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/28/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class StreamData: NSObject {
    fileprivate let _configEndpoint: String = "https://s3.amazonaws.com/data.calacademy.org/"
    fileprivate var _endpoint: String!
    fileprivate var _hlsKey: String!
    fileprivate var _task: URLSessionDataTask!
    fileprivate var _session: URLSession!
    
    var slug = "unknown"
    var streams: [[String:String]]!
    
    // defaults
    var minSecs: NSNumber = 6
    var width: NSNumber = 1280
    var height: NSNumber = 720
    
    var donateStyles: [[String : [String : String]]] = [
        [
            "button": [
                "normal": "stingray news ",
                "bold": "& more"
            ],
            "alert": [
                "title": "Animal antics, delivered to your inbox.",
                "body": "Get Academy Updates for email you actually look forward to.",
                "url": "https://www.calacademy.org/stay-connected/?src=stingrayslive",
                "confirm": "Subscribe"
            ]
        ],
        [
            "button": [
                "normal": "support ",
                "bold": "our stingrays"
            ],
            "alert": [
                "title": "Help the Academy zap extinction.",
                "body": "Your donation supports biodiversity research and conservation.",
                "url": "https://www.calacademy.org/donate/?src=stingrayslive",
                "confirm": "Donate"
            ]
        ]
    ]
    
    var alerts: [String: [String: String]] = [
        "donate": [
            "title": "",
            "body": "",
            "url": ""
        ],
        "logo": [
            "title": "Visit Us Online",
            "body": "Learn about events and exhibits, purchase tickets, submit feedback, and more!",
            "url": "http://www.calacademy.org/?src=stingrayslive"
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
        
        let url = URL(string: _configEndpoint + slug + "/data.json")!
        
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
        
        // minSecs
        if let myMinSecs = json["minSecs"].number {
            minSecs = myMinSecs
        }
        
        // size
        if let myWidth = json["width"].number {
            width = myWidth
        }
        
        if let myHeight = json["height"].number {
            height = myHeight
        }
        
        // donate styles
        if let myDonateStyles = json["donateStyles"].array {
            if (myDonateStyles.count > 0) {
                donateStyles = [[String : [String : String]]]()
                
                for donateStyle in myDonateStyles {
                    donateStyles.append([
                        "button": [
                            "normal": donateStyle["button"]["normal"].string!,
                            "bold": donateStyle["button"]["bold"].string!
                        ],
                        "alert": [
                            "title": donateStyle["alert"]["title"].string!,
                            "body": donateStyle["alert"]["body"].string!,
                            "url": donateStyle["alert"]["url"].string!,
                            "confirm": donateStyle["alert"]["confirm"].string!
                        ]
                    ])
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
            
            alerts["donate"] = donateStyles[0]["alert"]
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
                            var myStream = [
                                "id": stream["id"].string!,
                                "label": stream["label"].string!,
                                "asset": stream["asset"].string!
                            ]
                            
                            if (stream["logoShadowOpacity"].string != nil) {
                                myStream["logoShadowOpacity"] = stream["logoShadowOpacity"].string!
                            }
                            
                            if (stream["logoShadowScale"].string != nil) {
                                myStream["logoShadowScale"] = stream["logoShadowScale"].string!
                            }
                            
                            streams.append(myStream)
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
