//
//  NSManagedObject+Palette.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/16/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    func transform(dictionary: NSDictionary) {

        let name = dictionary.stringValueForKey("title")
        let id = dictionary.numberValueForKey("id").stringValue
        let username = dictionary.stringValueForKey("userName")
        let widths = dictionary.numberArrayValueForKey("colorWidths")
        let colors = dictionary.stringArrayValueForKey("colors").map({ (string) -> UIColor in
            return UIColor.hexColor(string)
        })
        
        assert(colors.count == widths.count, "color and color width should be equal")
        
        self.setValue(name, forKey: "name")
        self.setValue(id, forKey: "id")
        self.setValue(username, forKey: "username")
        self.setValue(widths, forKey: "widths")
        self.setValue(colors, forKey: "colors")
    }
}