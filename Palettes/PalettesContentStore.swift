//
//  PalettesContentStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreData

class PalettesContentStore: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    private let reuseIdentifier = "PaletteCell"
    
    // MARK: - UICollectionViewDataSource
    
    override init() {
        super.init()
        self.fetchedResultsController.delegate = self
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController.sections?[section] as NSFetchedResultsSectionInfo).numberOfObjects ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PaletteCell", forIndexPath: indexPath) as PaletteCell
        let palette = self.objectAtIndexPath(indexPath)
        
        let viewModel = PaletteViewModel(palette: palette)
        cell.viewModel = viewModel
        
        return cell
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // TODO: implement
    }
    
    // MARK: - Private
    
    var fetchedResultsController: NSFetchedResultsController = {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let fetchedResultsController = CoreDataManager.sharedManager.fetchedResultsControllerForEntityName("Palette", sortDescriptors: sortDescriptors)
        return fetchedResultsController
    }()
    
    func objectAtIndexPath(indexPath:NSIndexPath) -> Palette {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as Palette
        return object
    }
}
