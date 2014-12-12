//
//  NSData+JSON.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension NSData {
    func asDictionary() -> NSDictionary {
        var error : NSError?
        var options = NSJSONReadingOptions.MutableContainers
        return NSJSONSerialization.JSONObjectWithData(self, options:options, error:&error) as NSDictionary
    }
    
    func asArray() -> NSArray {
        var error : NSError?
        var options = NSJSONReadingOptions.MutableContainers
        if let array = NSJSONSerialization.JSONObjectWithData(self, options:options, error:&error) as? NSArray {
            return array
        }
        else {
            return NSArray()
        }
    }
}