//
//  Palette.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class Palette: NSObject, Printable {
    let title: String
    let username: String
    let colors: [UIColor]
    let widths: [NSNumber]
    let id: NSNumber
    
    override var description: String {
        return self.title
    }
    
    init(_ dictionary:NSDictionary) {
        self.id = dictionary.numberValueForKey("id")
        self.title = dictionary.stringValueForKey("title")
        self.username = dictionary.stringValueForKey("userName")
        self.widths = dictionary.numberArrayValueForKey("colorWidths")
        self.colors = dictionary.stringArrayValueForKey("colors").map({ (string) -> UIColor in
            return UIColor.hexColor(string)
        })
        
        super.init()
        
        assert(self.colors.count == self.widths.count, "color and color width should be equal")
    }
}
