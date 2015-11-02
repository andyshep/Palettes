//
//  Palette.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/16/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

class Palette: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var rank: NSNumber
    @NSManaged var username: String
    
    @NSManaged var colors: [AnyObject]
    @NSManaged var widths: [AnyObject]
}

extension Palette {
    class var entityName: String {
        return "Palette"
    }
    
    class var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "rank", ascending: true)]
    }
}
