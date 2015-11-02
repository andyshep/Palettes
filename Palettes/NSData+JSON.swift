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
        do {
            guard let dictionary = try NSJSONSerialization.JSONObjectWithData(self, options: .MutableContainers) as? NSDictionary else {
                return [:]
            }
            
            return dictionary
        }
        catch {
            return [:]
        }
    }
    
    func asArray() -> NSArray {
        do {
            guard let array = try NSJSONSerialization.JSONObjectWithData(self, options: []) as? NSArray else {
                return []
            }
            
            return array
        }
        catch {
            return []
        }
    }
}