//
//  PaletteColorView.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class PaletteColorView: UIView {
    
    var colors: [PaletteColor]? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        var offset = CGRectGetMinX(rect)
        let colors = self.colors ?? [PaletteColor]()
        
        for color in colors {
            let width = CGRectGetWidth(rect) * CGFloat(color.width)
            let path = UIBezierPath(rect: CGRectMake(offset, 0, width, CGRectGetHeight(rect)))
            
            color.fillColor.setFill()
            path.fill()
            
            offset += width
        }
    }
}
