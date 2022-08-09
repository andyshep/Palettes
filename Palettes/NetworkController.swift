//
//  NetworkController.swift
//  Palettes
//
//  Created by Andrew Shepard on 12/11/14.
//  Copyright (c) 2014 Andrew Shepard. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case badResponse
    case noSuccessStatusCode(statusCode: Int)
    case other(Error?)
}

struct NetworkController {
    
    /**
    Creates an NSURLSessionTask for the request
    
    :param: request A reqeust object to return a task for
    :param: completion
    
    :returns: An NSURLSessionTask associated with the request
    */
    
    static func task(_ request: URLRequest, completion: @escaping (Result<Data, Error>) -> ()) -> URLSessionTask {
        
        // handle the task completion job on the main thread
        let finished: (Result<Data, Error>) -> () = { result in
            DispatchQueue.main.async(execute: { () -> Void in
                completion(result)
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
