//
//  StreamData.swift
//  Sharks
//
//  Created by Rotter, Greg on 9/28/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

class StreamData: NSObject {
    var endpoint = "https://youtube.com/get_video_info?video_id"
    var connection:NSURLConnection!
    var data:NSMutableData!
    
    func connect(id: String) {
        // clear
        self.data = NSMutableData()
        
        let urlPath = endpoint + "=" + id
        let url = NSURL(string: urlPath)!
        let request = NSURLRequest(URL: url)
        
        if (connection != nil) {
            connection.cancel()
        }
        
        connection = NSURLConnection(request: request, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        self.data.appendData(data)
    }
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        NSNotificationCenter.defaultCenter().postNotificationName("dataError", object: nil)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        print("YouTube data loaded from " + connection.currentRequest.URL!.absoluteString)
        
        // split data from YouTube
        let datastring = NSString(data: data, encoding: NSUTF8StringEncoding)
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
}
