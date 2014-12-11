//
//  ColourLoversAPIRoutes.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

typealias Parameters = [String: String]

enum ColourLovers {
    case Random
    case TopPalettes
    case Palette(String)
}

protocol Path {
    var path: String { get }
}

protocol Request {
    func request(parameters: Parameters) -> NSURLRequest
}

extension ColourLovers: Path {
    var baseURL: String {
        return "http://www.colourlovers.com/api"
    }
    
    var path: String {
        switch self {
        case .Random:
            return "\(self.baseURL)/random"
        case .TopPalettes:
            return "\(self.baseURL)/palettes/top"
        case .Palette(let id):
            return "\(self.baseURL)/palettes/\(id)"
        }
    }
}

extension ColourLovers: Request {
    func request(parameters: Parameters) -> NSURLRequest {
        let path = self.path
        let queryString = self.queryStringWithParameters(parameters)
        
        let url = NSURL(string: "\(path)?\(queryString)")
        return NSURLRequest(URL: url!)
    }
    
    func queryStringWithParameters(parameters:Parameters) -> String {
        // Helper method for building query string from Dictionary
        var queryString = ""
        for parameter in parameters {
            if queryString != "" {
                queryString = queryString + "&"
            }
            queryString = queryString + parameter.0 + "=" + parameter.1
        }
        
        return queryString
    }
}