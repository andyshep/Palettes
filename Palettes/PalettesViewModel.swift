//
//  PalettesViewModel.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import UIKit

class PalettesViewModel: NSObject, UICollectionViewDataSource {
    weak var collectionView: UICollectionView!
    private var palettes: [Palette] = []
    private let reuseIdentifier = "PaletteCell"
    
    init(_ collectionView:UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        self.collectionView.registerClass(PaletteCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.palettes.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PaletteCell", forIndexPath: indexPath) as PaletteCell
        
        cell.palette = self.palettes[indexPath.row]
        
        if self.palettes.count - 15 <= indexPath.row {
            self.loadPalettes(self.palettes.count)
        }
        
        return cell
    }
    
    // MARK: - Private
    func loadPalettes() -> Void {
        let parameters = ["format": "json", "showPaletteWidths": "1", "numResults": "100"]
        let request = ColourLovers.TopPalettes.request(parameters)
        self.loadPalettes(request)
    }
    
    func loadPalettes(offset:Int) -> Void {
        let parameters = ["format": "json", "showPaletteWidths": "1", "numResults": "50", "resultOffset": String(offset)]
        let request = ColourLovers.TopPalettes.request(parameters)
        self.loadPalettes(request)
    }
    
    func loadPalettes(request:NSURLRequest) -> Void {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        NetworkController.loadURLRequest(request, completion: { (data, error) -> Void in
            if error != nil {
                println("error: \(error)")
            }
            else if let objs = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as? NSArray {
                var palettes: [Palette] = []
                
                for obj in objs {
                    if let dictionary = obj as? NSDictionary {
                        let palette = Palette(dictionary)
                        palettes.append(palette)
                    }
                }
                
                self.palettes += palettes
                self.collectionView.reloadData()
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        })
    }
}
