//
//  NetworkController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

typealias NetworkCompletion = (data:NSData?, error:NSError!) -> Void

class NetworkController: NSObject {
    
    class func loadURLRequest(request:NSURLRequest, completion:NetworkCompletion) {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...204:
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion(data: data, error: error)
                        })
                    default:
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion(data: nil, error: error)
                        })
                    }
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion(data: nil, error: error)
                })
            }
        })
        
        task.resume()
    }
}
