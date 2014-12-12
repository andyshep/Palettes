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
        self.collectionView.backgroundColor = UIColor.blackColor()
        
        self.viewModel = PalettesViewModel(collectionView)
        
        self.collectionView.collectionViewLayout = PalettesFlowLayout()
        self.collectionView.dataSource = self.viewModel
        
        self.viewModel.loadPalettes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

