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
    case success(Data)
    case failure(Reason)
}

extension Result {
    func description() -> String {
        switch self {
        case .success(let data):
            return "Success: \(data.count)"
        case .failure(let reason):
            return "Failure: \(reason.description())"
        }
    }
}

// define a Reason enum to represent a reason for failure

public enum Reason {
    case badResponse
    case noData
    case noSuccessStatusCode(statusCode: Int)
    case other(NSError)
}

extension Reason {
    func description() -> String {
        switch self {
        case .badResponse:
            return "Bad response object returned"
        case .noData:
            return "No response data"
        case .noSuccessStatusCode(let code):
            return "Bad status code: \(code)"
        case .other(let error):
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
    
    static func task(_ request:URLRequest, result: TaskResult) -> URLSessionTask {
        
        // handle the task completion job on the main thread
        let finished: TaskResult = {(taskResult) in
            DispatchQueue.main.async(execute: { () -> Void in
                result(result: taskResult)
            })
        }
        
        // return a basic NSURLSession for the request, with basic error handling
        return URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) -> Void in
            if err == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...204:
                        finished(result: Result.success(data!))
                    default:
                        let reason = Reason.noSuccessStatusCode(statusCode: httpResponse.statusCode)
                        finished(result: Result.failure(reason))
                    }
                } else {
                    finished(result: Result.failure(Reason.badResponse))
                }
            }
            else {
                finished(result: Result.failure(Reason.other(err!)))
            }
        })
    }
}
