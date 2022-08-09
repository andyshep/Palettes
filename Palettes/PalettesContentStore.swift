//
//  PalettesContentStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreData

final class PalettesContentStore: NSObject {
    private var objects: [Palette] = []
    
    weak var collectionView: UICollectionView? {
        didSet {
            self.objects = []
            collectionView?.reloadData()
            try? fetchedResultsController.performFetch()
        }
    }
    
    // lazy? also FIXME
    lazy var fetchedResultsController: NSFetchedResultsController<Palette> = {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let context = CoreDataManager.sharedManager.managedObjectContext!
        let fetchRequest = self.palettesFetchRequest(0)
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Palettes")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        return _fetchedResultsController!
    }()
    
    private var _fetchedResultsController: NSFetchedResultsController<Palette>? = nil
    
    override init() {
        super.init()
    }
    
    // MARK: Private
    
    /**
    Executes an asynchronous fetch reqest for the model objects at an offset
    
    :param: offset The index into the collection to begin retrieving objects from
    
    */
    
//    private func executeFetchRequest(_ offset: Int) throws -> Void {
//        let request = palettesFetchRequest(offset)
//        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
//            let count = result.finalResult?.count ?? 0
//            if count > 0 {
//                if let palettes = result.finalResult {
//                    self.objects += palettes
//                    self.collectionView?.reloadData()
//                }
//            }
//        }
//
//        guard let context = CoreDataManager.sharedManager.managedObjectContext else { return }
//        try context.execute(asyncRequest)
//    }
    
    /**
    Executes the fetch request associated with the fetched results controller
    
    */
    
//    private func performFetch() throws -> Void {
//        try self.fetchedResultsController.performFetch()
//    }
    
    private func palettesFetchRequest(_ offset:Int) -> NSFetchRequest<Palette> {
        let request = NSFetchRequest<Palette>(entityName: Palette.entityName)
        request.fetchOffset = offset
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        
        return request
    }
    
    private func objectAtIndexPath(_ indexPath: IndexPath) -> Palette {
//        let object = self.objects[indexPath.row]
        let object = fetchedResultsController.fetchedObjects?[(indexPath as NSIndexPath).row]
        return object!
    }
}

// MARK: UICollectionViewDataSource

extension PalettesContentStore: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaletteCell.reuseIdentifier, for: indexPath) as! PaletteCell
        let palette = objectAtIndexPath(indexPath)
        
        let viewModel = PaletteViewModel(palette: palette)
        cell.viewModel = viewModel
        
        return cell
    }
}

// MARK: NSFetchedResultsControllerDelegate

extension PalettesContentStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.reloadData()
    }
}
