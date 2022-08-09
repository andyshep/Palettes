//
//  PaletteColorView.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

final class PaletteColorView: UIView {
    
    var colors: [PaletteColor]? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        let rect = layer.bounds
        let colors = self.colors ?? [PaletteColor]()
        
        var offset = rect.minX
        
        for color in colors {
            let width = rect.width * CGFloat(color.width)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = CGRect(x: offset, y: 0, width: width, height: rect.height)
            shapeLayer.backgroundColor = color.fillColor.cgColor
            
            layer.addSublayer(shapeLayer)
            
            offset += width
        }
    }
}
