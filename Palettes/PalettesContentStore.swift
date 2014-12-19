//
//  PalettesContentStore.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreData

class PalettesContentStore: NSObject, UICollectionViewDataSource {
    private var objects: [Palette] = []
    
    weak var collectionView: UICollectionView? {
        didSet {
            self.objects = []
            self.collectionView?.reloadData()
            self.executeFetchRequest(offset: 0)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override init() {
        super.init()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.objects.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PaletteCell.reuseIdentifier, forIndexPath: indexPath) as PaletteCell
        let palette = self.objectAtIndexPath(indexPath)
        
        let viewModel = PaletteViewModel(palette: palette)
        cell.viewModel = viewModel
        
        if indexPath.row + 10 > self.objects.count {
            self.executeFetchRequest(offset: self.objects.count)
        }
        
        return cell
    }
    
    // MARK: - Private
    
    func executeFetchRequest(#offset: Int) -> Void {
        let request = palettesFetchRequest(offset: offset)
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (result) -> Void in
            let count = result.finalResult?.count
            if count > 0 {
                println("executeFetchRequest received \(count!) objects")
                
                if let palettes = result.finalResult as? [Palette] {
                    self.objects += palettes
                    self.collectionView?.reloadData()
                }
            }
            else {
                println("received no objects...")
            }
        }
        
        let context = CoreDataManager.sharedManager.managedObjectContext
        context?.performBlock({ () -> Void in
            var error: NSError?
            let result = context?.executeRequest(asyncRequest, error: &error)
        })
    }
    
    func palettesFetchRequest(#offset:Int) -> NSFetchRequest {
        let request = NSFetchRequest(entityName: Palette.entityName)
        request.fetchOffset = offset
        request.fetchLimit = 30
        request.sortDescriptors = Palette.defaultSortDescriptors
        
        return request
    }
    
    func objectAtIndexPath(indexPath:NSIndexPath) -> Palette {
        let object = self.objects[indexPath.row]
        return object
    }
}
