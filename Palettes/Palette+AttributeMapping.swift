//
//  Palette+AttributeMapping.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/18/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import UIKit

extension Palette {
    func transformWithDictionary(_ dictionary: NSDictionary) {
        self.name = dictionary.stringValueForKey("title")
        self.id = dictionary.numberValueForKey("id").stringValue
        self.rank = dictionary.numberValueForKey("rank").intValue
        self.username = dictionary.stringValueForKey("userName")
        self.widths = dictionary.numberArrayValueForKey("colorWidths")
        self.colors = dictionary.stringArrayValueForKey("colors").map({ (string) -> UIColor in
            return UIColor.hexColor(string as String)
        })
        
        assert(colors.count == widths.count, "color and color width should be equal")
    }
    
    func transformWithPalette(_ palette: Palette) {
        self.name = palette.name
        self.id = palette.id
        self.rank = palette.rank
        self.username = palette.username
        self.widths = palette.widths
        self.colors = palette.colors
    }
    
    class func extractAttributeValues(_ dictionary: NSDictionary) -> NSDictionary {
//        let values = NSMutableDictionary()
        
        let name = dictionary.stringValueForKey("title")
        let id = dictionary.numberValueForKey("id").stringValue
        let rank = dictionary.numberValueForKey("rank").intValue
        let username = dictionary.stringValueForKey("userName")
        let widths = dictionary.numberArrayValueForKey("colorWidths")
        let colors = dictionary.stringArrayValueForKey("colors").map({ (string) -> UIColor in
            return UIColor.hexColor(string as String)
        })
        
        assert(colors.count == widths.count, "color and color width should be equal")
        
        return ["name": name, "id": id, "rank": rank, "username": username, "widths": widths, "colors": colors]
    }
}
