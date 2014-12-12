//
//  NSDictionary+Parsing.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension NSDictionary {
    func stringValueForKey(key: String) -> String {
        if let string = self[key] as? String {
            return string
        }
        return ""
    }
    
    func numberValueForKey(key: String) -> NSNumber {
        if let number = self[key] as? NSNumber {
            return number
        }
        return NSNumber(integer: NSNotFound)
    }
    
    func numberArrayValueForKey(key: String) -> [NSNumber] {
        if let numbers = self.valueForKey(key) as? [NSNumber] {
            return numbers
        }
        return []
    }
    
    func stringArrayValueForKey(key: String) -> [NSString] {
        if let strings = self.valueForKey(key) as? [NSString] {
            return strings
        }
        return []
    }
}