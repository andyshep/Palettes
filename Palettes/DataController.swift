//
//  DataController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/15/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

typealias LoadCompletion = (objects: [AnyObject]) -> Void

class DataController: NSObject {
    
    class func loadPalettesFromJSON() -> [AnyObject] {
        let filePath: String? = NSBundle.mainBundle().pathForResource("palettes", ofType: "json")
        var err: NSError?
        let data: NSData = NSData(contentsOfFile: filePath!)!
        let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as! NSArray
        
        if err != nil {
            println("error: \(err!.localizedDescription)")
        }
        
        var palettes: [AnyObject] = []
        for obj in jsonResult {
            if let paletteObj = obj as? NSDictionary {
                palettes.append(paletteObj)
            }
        }
        
        return palettes
    }
    
    class func loadPalettesFromJSON(completion: LoadCompletion) -> Void {
        let palettes = loadPalettesFromJSON()
        completion(objects: palettes)
    }
    
    class func loadPalettes(completion: LoadCompletion) -> Void {
        let request = NSFetchRequest(entityName: "Palette")
        let context = CoreDataManager.sharedManager.managedObjectContext
        
        var error: NSError?
        var results = context?.executeFetchRequest(request, error: &error) as? [Palette]
        if (error == nil && results?.count == 0) {
            println("no palettes...")
        }
        else {
            println("found \(results!.count) palettes!!")
        }
    }
}
