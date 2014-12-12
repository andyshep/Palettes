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
            self.colorView.palette = palette
            self.titleLabel.text = palette?.title
            self.subtitleLabel.text = palette?.id.stringValue
            
            self.setNeedsDisplay()
        }
    }
    
    private var colorView: PaletteColorView
    private var titleLabel: UILabel
    private var subtitleLabel: UILabel
    
    override init(frame: CGRect) {
        self.colorView = PaletteColorView()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        
        super.init(frame: frame)
        
        self.colorView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.subtitleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.backgroundColor = UIColor.whiteColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.addSubview(colorView)
        self.addSubview(titleLabel)
        self.addSubview(subtitleLabel)
        
        self.addConstraints(colorViewConstraints)
        self.addConstraints(titleLabelConstraints)
        self.addConstraints(subtitleLabelConstraints)
    }
    
    lazy var titleLabelConstraints: [AnyObject] = {
        var constraints: [AnyObject] = []
        
        let views = ["titleLabel": self.titleLabel, "colorView": self.colorView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[titleLabel]", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[colorView]-8-[titleLabel]-8-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        
        constraints += horizontalConstraints
        constraints += verticalConstraints
        
        return constraints
    }()
    
    lazy var subtitleLabelConstraints: [AnyObject] = {
        var constraints: [AnyObject] = []
        
        let views = ["subtitleLabel": self.subtitleLabel, "colorView": self.colorView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[subtitleLabel]-8-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[colorView]-8-[subtitleLabel]-8-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        
        constraints += horizontalConstraints
        constraints += verticalConstraints
        
        return constraints
        }()
    
    lazy var colorViewConstraints: [AnyObject] = {
        var constraints: [AnyObject] = []
        
        let views = ["colorView": self.colorView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[colorView]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[colorView]-40-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        
        constraints += horizontalConstraints
        constraints += verticalConstraints
        
        return constraints
        }()
}
