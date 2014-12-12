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
    
    private var viewModel: PalettesViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Palettes"
        
        self.collectionView.registerClass(PaletteCell.self, forCellWithReuseIdentifier: "PaletteCell")
        self.collectionView.collectionViewLayout = PalettesFlowLayout()
        self.collectionView.backgroundColor = UIColor.blackColor()
        self.collectionView.indicatorStyle = .White
        
        self.viewModel = PalettesViewModel()
        self.collectionView.dataSource = self.viewModel
        
        RACObserve(self.viewModel, "palettes").subscribeNext { (_) -> Void in
            self.collectionView.reloadData()
        }
        
        RACObserve(self.viewModel, "loading").subscribeNext { (loading) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = loading.boolValue
        }
        
        self.viewModel.loadPalettes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

