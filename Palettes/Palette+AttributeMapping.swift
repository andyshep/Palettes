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
    func transform(#dictionary: NSDictionary) {
        self.name = dictionary.stringValueForKey("title")
        self.id = dictionary.numberValueForKey("id").stringValue
        self.username = dictionary.stringValueForKey("userName")
        self.widths = dictionary.numberArrayValueForKey("colorWidths")
        self.colors = dictionary.stringArrayValueForKey("colors").map({ (string) -> UIColor in
            return UIColor.hexColor(string)
        })
        
        assert(colors.count == widths.count, "color and color width should be equal")
    }
    
    func transform(#palette: Palette) {
        self.name = palette.name
        self.id = palette.id
        self.username = palette.username
        self.widths = palette.widths
        self.colors = palette.colors
    }
}