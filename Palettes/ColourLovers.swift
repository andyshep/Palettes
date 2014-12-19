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
    case TopPalettes
    case Palette(String)
    case PaletteCount
}

protocol Path {
    var path: String { get }
}

protocol Request {
    func request(#offset:Int) -> NSURLRequest
    func request(#offset:Int, limit:Int) -> NSURLRequest
}

extension ColourLovers: Path {
    var baseURL: String {
        return "http://www.colourlovers.com/api"
    }
    
    var path: String {
        switch self {
        case .TopPalettes:
            return "\(self.baseURL)/palettes/top"
        case .PaletteCount:
            return "\(self.baseURL)/stats/palettes"
        case .Palette(let id):
            return "\(self.baseURL)/palettes/\(id)"
        }
    }
}

extension ColourLovers: Request {
    func request() -> NSURLRequest {
        return self.request(offset: 0)
    }
    
    func request(#offset:Int) -> NSURLRequest {
        let parameters = ["format": "json", "showPaletteWidths": "1", "numResults": "50", "resultOffset": String(offset)]
        return self.request(parameters)
    }
    
    func request(#offset:Int, limit:Int) -> NSURLRequest {
        let parameters = ["format": "json", "showPaletteWidths": "1", "numResults": String(limit), "resultOffset": String(offset)]
        return self.request(parameters)
    }
    
    func countRequest() -> NSURLRequest {
        return self.request(["format": "json"])
    }
    
    func request(parameters: Parameters) -> NSURLRequest {
        let path = self.path
        let queryString = self.queryStringWithParameters(parameters)
        
        let url = NSURL(string: "\(path)?\(queryString)")
        return NSURLRequest(URL: url!)
    }
    
    func queryStringWithParameters(parameters:Parameters) -> String {
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