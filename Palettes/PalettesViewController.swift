//
//  PalettesViewController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class PalettesViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let contentStore = PalettesContentStore()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Palettes"
        
        self.collectionView.register(PaletteCell.self, forCellWithReuseIdentifier: PaletteCell.reuseIdentifier)
        self.collectionView.collectionViewLayout = PalettesFlowLayout()
        self.collectionView.backgroundColor = UIColor.black
        self.collectionView.indicatorStyle = .white
        
        self.contentStore.collectionView = self.collectionView
        self.collectionView.dataSource = self.contentStore
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

