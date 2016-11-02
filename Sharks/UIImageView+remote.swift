//
//  UIImageView+remote.swift
//  Sharks
//
//  Created by Rotter, Greg on 10/8/15.
//  Copyright © 2015 Greg Rotter. All rights reserved.
//

import UIKit

extension UIImageView {
    func download(_ link:String) {
        if let url = URL(string: link) {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) -> Void in
                guard let data = data , error == nil else {
                    return
                }
                
                DispatchQueue.main.async { () -> Void in
                    self.image = UIImage(data: data)
                }
            }).resume()
        }
    }
}
