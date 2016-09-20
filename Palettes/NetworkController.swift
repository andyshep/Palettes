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
    case failure(Error)
}

extension Result {
    func description() -> String {
        switch self {
        case .success(let data):
            return "Success: \(data.count)"
        case .failure(let error):
            return "Failure: \(error)"
        }
    }
}

public enum NetworkError: Error {
    case badResponse
    case noSuccessStatusCode(statusCode: Int)
    case other(Error?)
}

typealias TaskResult = (_ result: Result) -> Void

struct NetworkController {
    
    /**
    Creates an NSURLSessionTask for the request
    
    :param: request A reqeust object to return a task for
    :param: completion
    
    :returns: An NSURLSessionTask associated with the request
    */
    
    static func task(_ request: URLRequest, result: @escaping TaskResult) -> URLSessionTask {
        
        // handle the task completion job on the main thread
        let finished: TaskResult = {(taskResult) in
            DispatchQueue.main.async(execute: { () -> Void in
                result(taskResult)
            })
        }
        
        // return a basic NSURLSession for the request, with basic error handling
        return URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) -> Void in
            if err == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...204:
                        finished(Result.success(data!))
                    default:
                        let error = NetworkError.noSuccessStatusCode(statusCode: httpResponse.statusCode)
                        finished(Result.failure(error))
                    }
                } else {
                    finished(Result.failure(NetworkError.badResponse))
                }
            } else {
                finished(Result.failure(NetworkError.other(err)))
            }
        })
    }
}
