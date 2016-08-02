//
//  NSData+JSON.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension Data {
    func asDictionary() -> NSDictionary {
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: self, options: .mutableContainers) as? NSDictionary else {
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
            guard let array = try JSONSerialization.jsonObject(with: self, options: []) as? NSArray else {
                return []
            }
            
            return array
        }
        catch {
            return []
        }
    }
}
