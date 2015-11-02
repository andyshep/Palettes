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
    private var objects: [Palette] = []
    
    weak var collectionView: UICollectionView? {
        didSet {
            self.objects = []
            self.collectionView?.reloadData()
            self.performFetch()
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override init() {
        super.init()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.objects.count
        return self.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PaletteCell.reuseIdentifier, forIndexPath: indexPath) as! PaletteCell
        let palette = self.objectAtIndexPath(indexPath)
        
        let viewModel = PaletteViewModel(palette: palette)
        cell.viewModel = viewModel
        
        return cell
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.collectionView?.reloadData()
    }
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let context = CoreDataManager.sharedManager.managedObjectContext!
        let fetchRequest = self.palettesFetchRequest(0)
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Palettes")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    // MARK: - Private
    
    /**
    Executes an asynchronous fetch reqest for the model objects at an offset
    
    :param: offset The index into the collection to begin retrieving objects from
    
    */
    
    func executeFetchRequest(offset: Int) -> Void {
        let request = palettesFetchRequest(offset)
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
            let count = result.finalResult?.count
            if count > 0 {
                if let palettes = result.finalResult as? [Palette] {
                    self.objects += palettes
                    self.collectionView?.reloadData()
                }
            }
        }

        guard let context = CoreDataManager.sharedManager.managedObjectContext else { return }
        
        do {
            try context.executeRequest(asyncRequest)
        }
        catch (let error) {
            print("error executing fetch request: \(error)")
        }
        
    }
    
    /**
    Executes the fetch request associated with the fetched results controller
    
    */
    
    func performFetch() -> Void {
        do {
            try self.fetchedResultsController.performFetch()
        }
        catch (let error) {
            print("error performing fetch: \(error)")
        }
    }
    
    func palettesFetchRequest(offset:Int) -> NSFetchRequest {
        let request = NSFetchRequest(entityName: Palette.entityName)
        request.fetchOffset = offset
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        
        return request
    }
    
    func objectAtIndexPath(indexPath:NSIndexPath) -> Palette {
//        let object = self.objects[indexPath.row]
        let object = self.fetchedResultsController.fetchedObjects?[indexPath.row] as! Palette
        return object
    }
}
