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
    case topPalettes
    case palette(String)
    case paletteCount
}

protocol Path {
    var path: String { get }
}

protocol Request {
    func request(offset: Int, limit: Int) -> URLRequest
}

extension ColourLovers: Path {
    var baseURL: String {
        return "http://www.colourlovers.com/api"
    }
    
    var path: String {
        switch self {
        case .topPalettes:
            return "\(self.baseURL)/palettes/top"
        case .paletteCount:
            return "\(self.baseURL)/stats/palettes"
        case .palette(let id):
            return "\(self.baseURL)/palettes/\(id)"
        }
    }
}

extension ColourLovers: Request {
    func request(offset: Int = 0, limit: Int = 50) -> URLRequest {
        return request([
            "format": "json",
            "showPaletteWidths": "1",
            "numResults": String(limit),
            "resultOffset": String(offset)
        ])
    }
    
    func countRequest() -> URLRequest {
        return self.request(["format": "json"])
    }
    
    func request(_ parameters: Parameters) -> URLRequest {
        let path = self.path
        let queryString = self.queryStringWithParameters(parameters)
        
        let url = URL(string: "\(path)?\(queryString)")
        return URLRequest(url: url!)
    }
    
    func queryStringWithParameters(_ parameters:Parameters) -> String {
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
