//
//  UIImageView+remote.swift
//  Sharks
//
//  Created by Rotter, Greg on 10/8/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

extension UIImageView {
    func download(link:String) {
        if let url = NSURL(string: link) {
            NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, _, error) -> Void in
                guard let data = data where error == nil else {
                    return
                }
                
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.image = UIImage(data: data)
                }
            }).resume()
        }
    }
}