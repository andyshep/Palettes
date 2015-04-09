//
//  NetworkController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

// define a Result enum to represent the result of some operation

public enum Result {
    case Success(NSData)
    case Failure(Reason)
}

extension Result {
    func description() -> String {
        switch self {
        case .Success(let data):
            return "Success: \(data.length)"
        case .Failure(let reason):
            return "Failure: \(reason.description())"
        }
    }
}

// define a Reason enum to represent a reason for failure

public enum Reason {
    case BadResponse
    case NoData
    case NoSuccessStatusCode(statusCode: Int)
    case Other(NSError)
}

extension Reason {
    func description() -> String {
        switch self {
        case .BadResponse:
            return "Bad response object returned"
        case .NoData:
            return "No response data"
        case .NoSuccessStatusCode(let code):
            return "Bad status code: \(code)"
        case .Other(let error):
            return "\(error)"
        }
    }
}

typealias TaskResult = (result: Result) -> Void

struct NetworkController {
    
    /**
    Creates an NSURLSessionTask for the request
    
    :param: request A reqeust object to return a task for
    :param: completion
    
    :returns: An NSURLSessionTask associated with the request
    */
    
    static func task(request:NSURLRequest, result: TaskResult) -> NSURLSessionTask {
        
        // handle the task completion job on the main thread
        let finished: TaskResult = {(taskResult) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                result(result: taskResult)
            })
        }
        
        // return a basic NSURLSession for the request, with basic error handling
        return NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in
            if err == nil {
                if let httpResponse = response as? NSHTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...204:
                        finished(result: Result.Success(data))
                    default:
                        let reason = Reason.NoSuccessStatusCode(statusCode: httpResponse.statusCode)
                        finished(result: Result.Failure(reason))
                    }
                } else {
                    finished(result: Result.Failure(Reason.BadResponse))
                }
            }
            else {
                finished(result: Result.Failure(Reason.Other(err)))
            }
        })
    }
}
