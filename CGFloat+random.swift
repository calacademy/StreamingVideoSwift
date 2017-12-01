//
//  CGFloat+random.swift
//  Stringrays Live
//
//  Created by Rotter, Greg on 12/1/17.
//  Copyright © 2017 Greg Rotter. All rights reserved.
//

import CoreGraphics

public extension CGFloat {
    public static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (max - min) + min
    }
}
