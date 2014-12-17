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
        
        self.collectionView.registerClass(PaletteCell.self, forCellWithReuseIdentifier: "PaletteCell")
        self.collectionView.collectionViewLayout = PalettesFlowLayout()
        self.collectionView.backgroundColor = UIColor.blackColor()
        self.collectionView.indicatorStyle = .White
        
        self.contentStore.collectionView = self.collectionView
        self.collectionView.dataSource = self.contentStore
        
        RACObserve(self.contentStore, "fetchedResultsController.fetchedObjects").subscribeNext { (_) -> Void in
            self.collectionView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

