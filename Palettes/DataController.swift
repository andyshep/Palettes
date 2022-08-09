//
//  DataController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/15/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreData

//typealias LoadCompletion = (_ objects: [AnyObject]) -> Void
//
//struct DataController {
//    
//    func loadPalettesFromJSON() -> [AnyObject] {
//        guard let filePath = Bundle.main.path(forResource: "palettes", ofType: "json") else { return [] }
//        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return [] }
//        
//        do {
//            guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray else {
//                return []
//            }
//            
//            var palettes: [AnyObject] = []
//            for obj in jsonResult {
//                if let paletteObj = obj as? NSDictionary {
//                    palettes.append(paletteObj)
//                }
//            }
//            
//            return palettes
//        }
//        catch (let error) {
//            print("error loading palettes from JSON: \(error)")
//            return []
//        }
//    }
//    
//    func loadPalettesFromJSON(_ completion: LoadCompletion) -> Void {
//        let palettes = loadPalettesFromJSON()
//        completion(palettes)
//    }
//    
//    func loadPalettes(_ completion: LoadCompletion) -> Void {
//        guard let context = CoreDataManager.sharedManager.managedObjectContext else { return }
//        let request = NSFetchRequest<Palette>(entityName: "Palette")
//        
//        do {
//            let results = try context.fetch(request)
//            completion(results)
//        }
//        catch (let error) {
//            print("error loading palettes from context: \(error)")
//            completion([])
//        }
//    }
//}
