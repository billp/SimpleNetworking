//
//  TNRequest.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 14/02/2018.
//  Copyright © 2018 Vasilis Panagiotopoulos. All rights reserved.
//

import Foundation
import UIKit

//MARK: - Custom types
public typealias TNSuccessCallback<T> = (T)->()
public typealias TNFailureCallback = (_ error: TNError, _ data: Data?)->()

// MARK: - DEPRECATED TYPES
public typealias TNBeforeAllRequestsCallback = ()->()
public typealias TNAfterAllRequestsCallback = ()->()
public typealias TNBeforeEachRequestCallback = (_ call: TNRequest)->()
public typealias TNAfterEachRequestCallback = (_ call: TNRequest, _ data: Data?, _ response: URLResponse?, _ error: Error?)->()

//MARK: - Enums
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

/**
 The the body type of the request
*/
public enum TNRequestBodyType: String {
    /// The request params are sent as application/x-www-form-urlencoded mime type
    case xWWWFormURLEncoded = "application/x-www-form-urlencoded"
    /// The request params are sent as application/json mime type
    case JSON = "application/json"
}

public struct TNRequestConfiguration {
    public var cachePolicy: URLRequest.CachePolicy?
    public var timeoutInterval: TimeInterval?
    public var requestBodyType: TNRequestBodyType?
    
    public static let `default` = TNRequestConfiguration(cachePolicy: .useProtocolCachePolicy,
                                                             timeoutInterval: 60,
                                                             requestBodyType: .xWWWFormURLEncoded)
    
    public init() { }
    
    public init(cachePolicy: URLRequest.CachePolicy?,
                timeoutInterval: TimeInterval?,
                requestBodyType: TNRequestBodyType?) {
        self.cachePolicy = cachePolicy ?? TNRequestConfiguration.default.cachePolicy
        self.timeoutInterval = timeoutInterval ?? TNRequestConfiguration.default.timeoutInterval
        self.requestBodyType = requestBodyType ?? TNRequestConfiguration.default.requestBodyType
    }
    
    public init(cachePolicy: URLRequest.CachePolicy?) {
        self.init(cachePolicy: cachePolicy, timeoutInterval: nil, requestBodyType: nil)
    }
    public init(timeoutInterval: TimeInterval?) {
        self.init(cachePolicy: nil, timeoutInterval: timeoutInterval, requestBodyType: nil)
    }
    public init(requestBodyType: TNRequestBodyType?) {
        self.init(cachePolicy: nil, timeoutInterval: nil, requestBodyType: requestBodyType)
    }
}

open class TNRequest: TNOperation {
    //MARK: - Static properties
    public static var fixedHeaders = [String: String]()
    public static var allowEmptyResponseBody = false

    // MARK: - Internal properties
    internal var method: TNMethod!
    internal var currentQueue: TNQueue!
    internal var dataTask: URLSessionDataTask?
    internal var customError: TNError?
    internal var data: Data?
    internal var urlResponse: URLResponse?
    internal var params: [String: Any?]?
    internal var path: String
    internal var pathType: SNPathType = .normal

    // MARK: - Private properties
    private var headers: [String: String]?
    private var timeoutInterval: TimeInterval?
    
    // MARK: - Public properties
    public var cachePolicy: URLRequest.CachePolicy
    public var requestBodyType: TNRequestBodyType = .xWWWFormURLEncoded
        
    //MARK: - Initializers
    /**
     Initializes a TNRequest request
     
     - parameters:
         - method: The http method of request, e.g. .get, .post, .head, etc.
         - url: The URL of the request
         - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
         - params: A Dictionary as request params. If method is .get it automatically appends them to url, otherwise it sets them as request body.
         - configuration: A TNRequestConfiguration object
     */
    public init(method: TNMethod, url: String, headers: [String: String]? = nil, params: [String: Any?]? = nil, configuration: TNRequestConfiguration? = nil) {
        self.method = method
        self.headers = headers
        self.params = params
        self.pathType = .full
        self.path = url
        self.cachePolicy = configuration?.cachePolicy ?? TNRequestConfiguration.default.cachePolicy!
        self.timeoutInterval = configuration?.timeoutInterval ?? TNRequestConfiguration.default.timeoutInterval!
        self.requestBodyType = configuration?.requestBodyType ?? TNRequestConfiguration.default.requestBodyType!
    }
    
    /**
     Initializes a TNRequest request
     
     - parameters:
         - method: The http method of request, e.g. .get, .post, .head, etc.
         - url: The URL of the request
         - configuration: A TNRequestConfiguration object
     */
    convenience init(method: TNMethod, url: String, configuration: TNRequestConfiguration = TNRequestConfiguration()) {
        self.init(method: method, url: url, headers: nil, params: nil, configuration: configuration)
    }
    
    /**
     Initializes a TNRequest request
     
     - parameters:
         - method: The http method of request, e.g. .get, .post, .head, etc.
         - url: The URL of the request
         - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
     */
    convenience init(method: TNMethod, url: String, headers: [String: String]? = nil) {
        self.init(method: method, url: url, headers: nil, params: nil)
    }
    
    /**
     Initializes a TNRequest request
     
     - parameters:
         - method: The http method of request, e.g. .get, .post, .head, etc.
         - url: The URL of the request
         - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
         - configuration: A TNRequestConfiguration object
     */
    convenience init(method: TNMethod, url: String, headers: [String: String]? = nil, configuration: TNRequestConfiguration = TNRequestConfiguration()) {
        self.init(method: method, url: url, headers: nil, params: nil, configuration: configuration)
    }
    
    /**
     Initializes a TNRequest request
     
     - parameters:
         - route: a TNRouteProtocol enum value
     */
    public init(route: TNRouterProtocol) {
        let route = route.configure()
        self.method = route.method
        self.headers = route.headers
        self.params = route.params
        self.path = route.path.convertedPath()

        self.cachePolicy = TNEnvironment.current?.requestConfiguration?.cachePolicy ?? route.requestConfiguration!.cachePolicy!
        self.timeoutInterval = TNEnvironment.current?.requestConfiguration?.timeoutInterval ?? route.requestConfiguration!.timeoutInterval!
        self.requestBodyType = TNEnvironment.current?.requestConfiguration?.requestBodyType ?? route.requestConfiguration!.requestBodyType!
    }

    // MARK: - Create request
    /**
     Converts a TNRequest instance to asRequest
    */
    public func asRequest() throws -> URLRequest {
        
        let urlString = NSMutableString()
        
        if pathType == .normal {
            guard let currentEnvironment = TNEnvironment.current else { throw TNError.environmentNotSet }
            urlString.setString(currentEnvironment.description + "/" + path)
        }  else {
            urlString.setString(path)
        }
        
        // Create query string from the given params
        let queryString = try params?.filter({ $0.value != nil }).map { param -> String in
            if let value = String(describing: param.value!).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                return param.key + "=" + value
            } else {
                throw TNError.invalidParams
            }
        }.joined(separator: "&")
        
        // Append query string to url in case of .get method
        if method == .get && queryString != nil {
            urlString.append("?" + queryString!)
        }
        
        guard let url = URL(string: urlString as String) else {
            throw TNError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: cachePolicy)
        
        // Add headers
        if headers == nil && TNRequest.fixedHeaders.keys.count > 0 {
            headers = [:]
        }
        headers?.merge(TNRequest.fixedHeaders, uniquingKeysWith: { (_, new) in new })
        
        if let timeoutInterval = self.timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Set http method
        request.httpMethod = method.rawValue
        
        // Set body params if method is not get
        if ![TNMethod.get, TNMethod.head].contains(method) {
            request.addValue(requestBodyType.rawValue, forHTTPHeaderField: "Content-Type")
            
            if requestBodyType == .xWWWFormURLEncoded {
                request.httpBody = queryString?.data(using: .utf8)
            } else {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: params ?? [], options: .prettyPrinted)
                } catch {
                    throw TNError.invalidParams
                }
            }
        }
        
        return request
    }
    
    /**
     Cancels a TNRequest started request
     */
    open override func cancel() {
        super.cancel()
        dataTask?.cancel()
    }
    
    // MARK: - Helper methods
    internal func sessionDataTask(request: URLRequest, completionHandler: ((Data)->())?, onFailure: TNFailureCallback?) -> URLSessionDataTask {
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            var statusCode: Int?
            self.data = data
            self.urlResponse = urlResponse

            // Error handling
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    self.customError = TNError.cancelled(error)
                } else {
                    self.customError = TNError.networkError(error)
                }
            }
            else if let response = urlResponse as? HTTPURLResponse {
                statusCode = response.statusCode as Int?
            
                if statusCode != nil && statusCode! / 100 != 2 {
                    self.customError = TNError.notSuccess(statusCode!)
                } else if (data == nil || data!.isEmpty) && !TNRequest.allowEmptyResponseBody {
                    self.customError = TNError.responseDataIsEmpty
                }
            }

            if let customError = self.customError {
                DispatchQueue.main.async {
                    TNLog.logRequest(request: self)
                    onFailure?(customError, data)
                    self.handleDataTaskFailure()
                }
            } else {
                completionHandler?(data!)
            }
        }
        
        return dataTask
    }
    
    func callBeforeRequestHoooks() {
    }
    
    // MARK: - Operation
    open override func start() {
        _executing = true
        _finished = false
        dataTask?.resume()
    }
    
    func handleDataTaskCompleted() {
        _executing = false
        _finished = true
        
        currentQueue.afterOperationFinished(request: self, data: data, response: urlResponse, error: customError)
    }
    
    func handleDataTaskFailure() {
        switch currentQueue.failureMode {
        case .continue?:
            break
        case .cancelAll?:
            currentQueue.cancelAllOperations()
        default:
            break
        }
        
        _executing = false
        _finished = true
        
        currentQueue.afterOperationFinished(request: self, data: data, response: urlResponse, error: customError)
    }
    
    /**
     Adds a request to a queue and starts it's execution. The response object in success callback is of type Decodable
     
     - parameters:
        - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
        - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
        - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start<T:Decodable>(queue: TNQueue? = TNQueue.shared, responseType: T.Type, onSuccess: TNSuccessCallback<T>?, onFailure: TNFailureCallback?)  {
        currentQueue = queue ?? TNQueue.shared
        currentQueue.beforeOperationStart(request: self)
        
        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            onFailure?(error as! TNError, nil)
            self.handleDataTaskFailure()
            return
        }

        dataTask = sessionDataTask(request: request, completionHandler: { data in
            let object: T!
            
            do {
                object = try data.deserializeJSONData() as T
            } catch let error {
                self.customError = .cannotDeserialize(error)
                TNLog.logRequest(request: self)
                onFailure?(.cannotDeserialize(error), data)
                self.handleDataTaskFailure()
                return
            }
            
            DispatchQueue.main.sync {
                TNLog.logRequest(request: self)
                onSuccess?(object)
                self.handleDataTaskCompleted()
            }
            
            
        }, onFailure: { error, data in
            onFailure?(error, data)
            self.handleDataTaskFailure()
        })
        
        currentQueue.addOperation(self)
    }
    
    /**
     Adds a request to a queue and starts it's execution. The response object in success callback is of type UIImage
     
     - parameters:
         - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
         - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
         - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start<T: UIImage>(queue: TNQueue? = TNQueue.shared, responseType: T.Type, onSuccess: TNSuccessCallback<T>?, onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)
        
        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            onFailure?(error as! TNError, nil)
            self.handleDataTaskFailure()
            return
        }

        dataTask = sessionDataTask(request: request, completionHandler: { data in
            let image = T(data: data)
            
            if image == nil {
                self.customError = .responseInvalidImageData
                TNLog.logRequest(request: self)

                DispatchQueue.main.sync {
                    onFailure?(.responseInvalidImageData, data)
                }
                self.handleDataTaskFailure()
            } else {
                DispatchQueue.main.sync {
                    TNLog.logRequest(request: self)
                    onSuccess?(image!)
                    self.handleDataTaskCompleted()
                }
            }
        }, onFailure: { error, data in
            onFailure?(error, data)
            self.handleDataTaskFailure()
        })
        
        currentQueue.addOperation(self)
    }
    
    
    /**
     Adds a request to a queue and starts it's execution. The response object in success callback is of type String
     
     - parameters:
     - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
     - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
     - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start(queue: TNQueue? = TNQueue.shared, responseType: String.Type, onSuccess: TNSuccessCallback<String>?, onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)
        
        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            onFailure?(error as! TNError, nil)
            self.handleDataTaskFailure()
            return
        }
        
        dataTask = sessionDataTask(request: request, completionHandler: { data in
            DispatchQueue.main.async {
                TNLog.logRequest(request: self)
                
                if let string = String(data: data, encoding: .utf8) {
                    onSuccess?(string)
                    self.handleDataTaskCompleted()
                } else {
                    let error = TNError.cannotConvertToString
                    onFailure?(error, data)
                    self.handleDataTaskFailure()
                }
                
            }
        }, onFailure: { error, data in
            onFailure?(error, data)
            self.handleDataTaskFailure()
        })
        
        currentQueue.addOperation(self)
    }
    
    // For any other object
    /**
     Adds a request to a queue and starts it's execution. The response object in success callback is of type Data
     
     - parameters:
         - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
         - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
         - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start(queue: TNQueue? = TNQueue.shared, responseType: Data.Type, onSuccess: TNSuccessCallback<Data>?, onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)
        
        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            onFailure?(error as! TNError, nil)
            self.handleDataTaskCompleted()
            return
        }
        
        dataTask = sessionDataTask(request: request, completionHandler: { data in
            DispatchQueue.main.async {
                TNLog.logRequest(request: self)
                onSuccess?(data)
                self.handleDataTaskCompleted()
            }
        }, onFailure: { error, data in
            onFailure?(error, data)
            self.handleDataTaskFailure()
        })
        
        currentQueue.addOperation(self)
    }
}
