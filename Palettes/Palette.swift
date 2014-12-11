//
//  Palette.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class Palette: NSObject, Printable {
    let title: String
    let username: String
    let colors: [UIColor]
    let widths: [NSNumber]
    
    override var description: String {
        return self.title
    }
    
    init(_ dictionary:NSDictionary) {
        self.title = dictionary.stringValueForKey("title")
        self.username = dictionary.stringValueForKey("userName")
        self.widths = dictionary.numberArrayValueForKey("colorWidths")
        self.colors = dictionary.stringArrayValueForKey("colors").map({ (string) -> UIColor in
            return UIColor.hexColor(string)
        })
        
        super.init()
    }
}

extension NSDictionary {
    func stringValueForKey(key: String) -> String! {
        if let string = self[key] as? String {
            return string
        }
        return ""
    }
    
    func numberArrayValueForKey(key: String) -> [NSNumber]! {
        if let numbers = self.valueForKey(key) as? [NSNumber] {
            return numbers
        }
        
        return []
    }
    
    func stringArrayValueForKey(key: String) -> [NSString]! {
        if let strings = self.valueForKey(key) as? [NSString] {
            return strings
        }
        
        return []
    }
}
