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
    weak var collectionView: UICollectionView? {
        didSet {
            collectionView?.reloadData()
            try? fetchedResultsController.performFetch()
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Palette> = {
        let controller = NSFetchedResultsController(
            fetchRequest: palettesFetchRequest(0),
            managedObjectContext: CoreDataManager.sharedManager.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: "Palettes"
        )
        
        controller.delegate = self
        
        return controller
    }()
    
    override init() {
        super.init()
        
        // FIXME: make this a publisher?
        Task {
            let container = CoreDataManager.sharedManager.persistentStoreContainer
            let _ = try? await container.loadPersistentStores()
        }
    }
    
    // MARK: Private
    
    private func palettesFetchRequest(_ offset: Int) -> NSFetchRequest<Palette> {
        let request = NSFetchRequest<Palette>(entityName: Palette.entityName)
        request.fetchOffset = offset
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        
        return request
    }
    
    private func objectAtIndexPath(_ indexPath: IndexPath) -> Palette {
        assert(indexPath.row < fetchedResultsController.fetchedObjects!.count)
        
        guard
            let object = fetchedResultsController.fetchedObjects?[indexPath.row]
        else {
            fatalError("object not found")
        }
        
        return object
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
