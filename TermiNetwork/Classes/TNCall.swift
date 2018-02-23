//
//  SRCall.swift
//  ServiceRouter
//
//  Created by Vasilis Panagiotopoulos on 14/02/2018.
//  Copyright © 2018 Vasilis Panagiotopoulos. All rights reserved.
//

import Foundation

public typealias TNSuccessCallback<T> = (T)->()
public typealias TNFailureCallback = (TNError, Data?)->()


public enum TNMethod: String {
    case get
    case head
    case post
    case put
    case delete
    case connect
    case options
    case trace
    case patch
}

public enum TNError: Error {
    case invalidURL
    case invalidParams
    case responseDataIsEmpty
    case responseInvalidImageData
    case environmentNotSet
    case cannotDeserialize
    case networkError(Error)
    case notSuccess(Int)
}

public enum TNCallSerializationType {
    case JSON
    case image
}

public typealias TNRouteReturnType = (method: TNMethod, path: TNPath, params: [String: Any?]?, headers: [String: String]?)

public protocol TNRouteProtocol {
    func construct() -> TNRouteReturnType
}

open class TNCall {
    static var fixedHeaders = [String: String]()
    var headers: [String: String]?
    var method: TNMethod!
    var path: String
    var cachePolicy: URLRequest.CachePolicy
    var timeoutInterval: TimeInterval?
    var params: [String: Any?]?
    private var pathType: SNPathType = .normal
    private var dataTask: URLSessionDataTask?
    
    //MARK: - Initializers
    public init(method: TNMethod, headers: [String: String]?, cachePolicy: URLRequest.CachePolicy?, timeoutInterval: TimeInterval?, path: TNPath, params: [String: Any?]?) {
        self.method = method
        self.headers = headers
        self.path = path.components.joined(separator: "/")
        self.cachePolicy = cachePolicy ?? .useProtocolCachePolicy
        self.timeoutInterval = timeoutInterval
        self.params = params
    }
    
    public convenience init(method: TNMethod, headers: [String: String], path: TNPath, params: [String: Any?]?) {
        self.init(method: method, headers: headers, cachePolicy: nil, timeoutInterval: nil, path: path, params: params)
    }
    
    public convenience init(method: TNMethod, path: TNPath, params: [String: Any?]?) {
        self.init(method: method, headers: nil, cachePolicy: nil, timeoutInterval: nil, path: path, params: nil)
    }

    public convenience init(route: TNRouteProtocol) {
        let params = route.construct()
        
        self.init(method: params.method, headers: params.headers, cachePolicy: nil, timeoutInterval: nil, path: params.path, params: params.params)
    }
    
    // Convenience method for passing a string instead of path
    public convenience init(method: TNMethod, url: String, params: [String: Any?]?) {
        self.init(method: method, headers: nil, cachePolicy: nil, timeoutInterval: nil, path: TNPath("-"), params: nil)
        self.pathType = .full
        self.path = url
    }
    
    // MARK: - Create request
    public func asRequest() throws -> URLRequest {
        guard let currentEnvironment = TNEnvironment.current else { throw TNError.environmentNotSet }
        
        let urlString = pathType == .normal ? currentEnvironment.description + "/" + path : path
        
        guard let url = URL(string: urlString) else {
            throw TNError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: currentEnvironment.timeoutInterval)
        
        params?.merge(TNCall.fixedHeaders, uniquingKeysWith: { (_, new) in new })
        
        request.allHTTPHeaderFields = params as? [String : String]
        request.httpMethod = method.rawValue
        
        if timeoutInterval != nil {
            request.timeoutInterval = timeoutInterval!
        }
        if params != nil {
            let formBody = params?.map({ (arg) -> String in
                return arg.key + "=" + String(describing: arg.value!)
            }).joined(separator: "&")
            
            request.httpBody = formBody?.data(using: String.Encoding.utf8)
        }
        
        return request
    }
    
    // Cancel data task
    public func cancel() {
        dataTask?.cancel()
    }
    
    // MARK: - Helper methods
    private func sessionDataTask(request: URLRequest, completionHandler: @escaping (Data)->(), onFailure: @escaping TNFailureCallback) throws -> URLSessionDataTask {
        
        dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            var customError: TNError?
            var statusCode: Int?
            
            if let networkError = error {
                customError = TNError.networkError(networkError)
            }
            
            if let response = urlResponse as? HTTPURLResponse{
                statusCode = response.statusCode as Int?
            
                if statusCode != nil && statusCode! / 100 != 2 {
                    customError = TNError.notSuccess(statusCode!)
                }
            }
            
            if customError != nil {
                _ = TNLog(call: self, message: "Error: " + (error?.localizedDescription ?? "")! + ", urlResponse:" + (urlResponse?.description ?? "")!)
                
                DispatchQueue.main.sync {
                    onFailure(customError!, data)
                }
            }
            else if data == nil {
                _ = TNLog(call: self, message: "Empty body received")
                
                DispatchQueue.main.sync {
                    onFailure(TNError.responseDataIsEmpty, data)
                }
            } else {
                completionHandler(data!)
            }
        }
        
        return dataTask!
    }
    
    // MARK: - Start requests
    
    // Deserialize objects with Decodable
    public func start<T>(onSuccess: @escaping TNSuccessCallback<T>, onFailure: @escaping TNFailureCallback) throws where T: Decodable {
        let request = try asRequest()

        try sessionDataTask(request: request, completionHandler: { data in
            
            guard let object: T = try? data.deserializeJSONData() else {
                _ = TNLog(call: self, message: "Cannot deserialize data. Check your models", responseData: data)

                onFailure(TNError.cannotDeserialize, data)
                return
            }
            
            _ = TNLog(call: self, message: "Successfully deserialized data", responseData: data)

            DispatchQueue.main.sync {
                onSuccess(object)
            }

        }, onFailure: onFailure).resume()
    }
    
    // Deserialize objects with UIImage
    public func start<T>(onSuccess: @escaping TNSuccessCallback<T>, onFailure: @escaping TNFailureCallback) throws where T: UIImage {
        let request = try asRequest()
        
        try sessionDataTask(request: request, completionHandler: { data in
            let image = T(data: data)
            
            if image == nil {
                _ = TNLog(call: self, message: "Unable to deserialize image (data not an image)")

                DispatchQueue.main.sync {
                    onFailure(TNError.responseInvalidImageData, data)
                }
            } else {
                DispatchQueue.main.sync {
                    _ = TNLog(call: self, message: "Successfully deserialized image")

                    onSuccess(image!)
                }
            }
        }, onFailure: onFailure).resume()
    }
    
    // For any other object
    public func start(onSuccess: @escaping TNSuccessCallback<Data>, onFailure: @escaping TNFailureCallback) throws {
        try sessionDataTask(request: try asRequest(), completionHandler: { data in
            DispatchQueue.main.sync {
                onSuccess(data)
            }
        }, onFailure: onFailure).resume()
    }
}
