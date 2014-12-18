//
//  ArrayTransformer.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/16/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

class ArrayTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        return NSKeyedArchiver.archivedDataWithRootObject(value!)
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let data = value as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data)
        }
        return []
    }
}
