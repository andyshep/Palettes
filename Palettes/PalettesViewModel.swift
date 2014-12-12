//
//  PalettesViewModel.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class PalettesViewModel: NSObject, UICollectionViewDataSource {
    dynamic var palettes: [PaletteViewModel] = []
    dynamic var loading: NSNumber = NSNumber(bool: false)
    
    private let reuseIdentifier = "PaletteCell"
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.palettes.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PaletteCell", forIndexPath: indexPath) as PaletteCell
        cell.viewModel = self.palettes[indexPath.row]
        
        if self.palettes.count - 15 <= indexPath.row {
            self.loadPalettes(self.palettes.count)
        }
        
        return cell
    }
    
    // MARK: - Load Palettes
    
    func loadPalettes() -> Void {
        self.loadPalettes(0)
    }
    
    // MARK: - Private
    
    func loadPalettes(offset:Int) -> Void {
        self.loading = NSNumber(bool: true)
        
        let request = ColourLovers.TopPalettes.request(offset)
        NetworkController.signalForRequest(request).subscribeNext({ (result) -> Void in
            if let data = result as? NSData {
                let sequence: RACSequence = data.asArray().rac_sequence
                let palettes = sequence.map({ (obj) -> AnyObject! in
                    if let dictionary = obj as? NSDictionary {
                        let palette = PaletteViewModel(palette: Palette(dictionary))
                        return palette
                    }
                    return nil
                }).array
                
                self.palettes += palettes as [PaletteViewModel]
                self.loading = NSNumber(bool: false)
            }
        }, error: { (error) -> Void in
            println("error: \(error)")
        })
    }
}
