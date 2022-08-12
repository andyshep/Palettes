//
//  ArrayTransformer.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/16/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import UIKit

final class ArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        return try? NSKeyedArchiver.archivedData(
            withRootObject: value,
            requiringSecureCoding: false
        )
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedArrayOfObjects(
            ofClasses: [UIColor.self, NSNumber.self],
            from: data
        )
    }
}
