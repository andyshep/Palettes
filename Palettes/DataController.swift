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
        let data: NSData = NSData(contentsOfFile: filePath!)!
        
        do {
            guard let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSArray else {
                return []
            }
            
            var palettes: [AnyObject] = []
            for obj in jsonResult {
                if let paletteObj = obj as? NSDictionary {
                    palettes.append(paletteObj)
                }
            }
            
            return palettes
        }
        catch (let error) {
            print("error loading palettes from JSON: \(error)")
            return []
        }
    }
    
    class func loadPalettesFromJSON(completion: LoadCompletion) -> Void {
        let palettes = loadPalettesFromJSON()
        completion(objects: palettes)
    }
    
    class func loadPalettes(completion: LoadCompletion) -> Void {
        guard let context = CoreDataManager.sharedManager.managedObjectContext else { return }
        let request = NSFetchRequest(entityName: "Palette")
        
        do {
            guard let results = try context.executeFetchRequest(request) as? [Palette] else {
                completion(objects: [])
                return
            }
            
            completion(objects: results)
        }
        catch (let error) {
            print("error loading palettes from context: \(error)")
            completion(objects: [])
        }
    }
}
