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
            self.setNeedsLayout()
        }
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        let rect = layer.bounds
        let colors = self.colors ?? [PaletteColor]()
        
        var offset = CGRectGetMinX(rect)
        
        for color in colors {
            let width = CGRectGetWidth(rect) * CGFloat(color.width)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = CGRectMake(offset, 0, width, CGRectGetHeight(rect))
            shapeLayer.backgroundColor = color.fillColor.CGColor
            
            layer.addSublayer(shapeLayer)
            
            offset += width
        }
    }
}
