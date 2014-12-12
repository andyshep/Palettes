//
//  UIColor+HexColors.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

extension UIColor {
    
    // http://stackoverflow.com/a/27203691
    
    class func hexColor(string: String) -> UIColor {
        let set = NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet
        var colorString = string.stringByTrimmingCharactersInSet(set).uppercaseString
        
        if (colorString.hasPrefix("#")) {
            colorString = colorString.substringFromIndex(advance(colorString.startIndex, 1))
        }
        
        if (countElements(colorString) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue: UInt32 = 0
        NSScanner(string: colorString).scanHexInt(&rgbValue)
        
        return UIColor(
            red:   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue:  CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}