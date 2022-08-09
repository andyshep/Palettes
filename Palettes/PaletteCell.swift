//
//  PaletteCell.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

final class PaletteCell: UICollectionViewCell {
    
    class var reuseIdentifier: String {
        return "PaletteCell"
    }
    
    var viewModel: PaletteViewModel? {
        didSet {
            self.titleLabel.text = viewModel?.name
            self.subtitleLabel.text = viewModel?.rank
            self.colorView.colors = viewModel?.colors
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
        
        self.colorView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.backgroundColor = UIColor.white
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
    
    // MARK: - Constraints
    
    lazy var titleLabelConstraints: [NSLayoutConstraint] = {
        let views: [String: Any] = ["titleLabel": self.titleLabel, "colorView": self.colorView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[titleLabel]", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[colorView]-8-[titleLabel]-8-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        
        var constraints: [NSLayoutConstraint] = []
        constraints.append(contentsOf: horizontalConstraints)
        constraints.append(contentsOf: verticalConstraints)
        
        return constraints
    }()
    
    lazy var subtitleLabelConstraints: [NSLayoutConstraint] = {
        let views: [String: Any] = ["subtitleLabel": self.subtitleLabel, "colorView": self.colorView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[subtitleLabel]-8-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[colorView]-8-[subtitleLabel]-8-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        
        var constraints: [NSLayoutConstraint] = []
        constraints.append(contentsOf: horizontalConstraints)
        constraints.append(contentsOf: verticalConstraints)
        
        return constraints
    }()
    
    lazy var colorViewConstraints: [NSLayoutConstraint] = {
        let views = ["colorView": self.colorView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[colorView]-8-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[colorView]-40-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
        
        var constraints: [NSLayoutConstraint] = []
        constraints.append(contentsOf: horizontalConstraints)
        constraints.append(contentsOf: verticalConstraints)
        
        return constraints
    }()
}
