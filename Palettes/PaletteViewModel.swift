//
//  PaletteViewModel.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/12/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

typealias PaletteColor = (fillColor: UIColor, width: Double)

class PaletteViewModel: NSObject {
    var palette: Palette
    
    init(palette: Palette) {
        self.palette = palette
        super.init()
    }
    
    var name: String {
        return self.palette.name
    }
    
    var rank: String {
        return self.palette.rank.stringValue
    }
    
    lazy var colors: [PaletteColor] = {
        var colors: [PaletteColor] = []
        for index in 0..<self.palette.colors.count {
            let color = self.palette.colors[index] as! UIColor
            let width = self.palette.widths[index].doubleValue
            let element: PaletteColor = (color, width)
            colors.append(element)
        }
        
        return colors
    }()
}
