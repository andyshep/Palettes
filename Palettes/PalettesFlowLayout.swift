//
//  PalettesFlowLayout.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

final class PalettesFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        self.itemSize = CGSize(width: UIScreen.main.bounds.width - 16.0, height: 172.0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
