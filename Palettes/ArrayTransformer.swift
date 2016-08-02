//
//  ArrayTransformer.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/16/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

class ArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: AnyObject?) -> AnyObject? {
        return NSKeyedArchiver.archivedData(withRootObject: value!)
    }
    
    override func reverseTransformedValue(_ value: AnyObject?) -> AnyObject? {
        if let data = value as? Data {
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        return []
    }
}
