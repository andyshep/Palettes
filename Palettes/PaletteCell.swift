//
//  PaletteCell.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class PaletteCell: UICollectionViewCell {
    
    var palette: Palette? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        var offset = CGRectGetMinX(rect)
        
        for index in 0..<self.palette!.widths.count {
            let color = self.palette!.colors[index]
            let colorWidth = self.palette!.widths[index]
            let width = CGRectGetWidth(rect) * CGFloat(colorWidth.floatValue)
            let path = UIBezierPath(rect: CGRectMake(offset, 0, width, CGRectGetHeight(rect)))
            
            color.setFill()
            path.fill()
            
            offset += width
        }
    }
}
