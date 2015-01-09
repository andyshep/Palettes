//
//  NetworkController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

typealias TaskCompletion = (data: NSData!, error: NSError!) -> Void

class NetworkController: NSObject {
    
    class func task(request:NSURLRequest, completion:TaskCompletion) -> NSURLSessionTask {
        
        let finished: TaskCompletion = {(data, error) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data: data, error: error)
            })
        }
        
        let success: NSData -> Void = {(data) in
            finished(data: data, error: nil)
        }
        
        let error: NSError! -> Void = {(error) in
            finished(data: nil, error: error)
        }
        
        return NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in
            if err == nil {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...204:
                        success(data)
                    default:
                        error(err)
                    }
                } else {
                    error(err)
                }
            }
            else {
                error(err)
            }
        })
    }
}
