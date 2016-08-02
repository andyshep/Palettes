//
//  NSURL+Directories.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/17/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

extension URL {
    static func applicationDocumentsDirectory() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }
}
