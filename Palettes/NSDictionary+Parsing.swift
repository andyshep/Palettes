//
//  NSDictionary+Parsing.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension NSDictionary {
    func stringValueForKey(_ key: String) -> String {
        if let string = self[key] as? String {
            return string
        }
        return ""
    }
    
    func numberValueForKey(_ key: String) -> NSNumber {
        if let number = self[key] as? NSNumber {
            return number
        }
        return NSNumber(value: NSNotFound)
    }
    
    func numberArrayValueForKey(_ key: String) -> [NSNumber] {
        if let numbers = self.value(forKey: key) as? [NSNumber] {
            return numbers
        }
        return []
    }
    
    func stringArrayValueForKey(_ key: String) -> [NSString] {
        if let strings = self.value(forKey: key) as? [NSString] {
            return strings
        }
        return []
    }
}
