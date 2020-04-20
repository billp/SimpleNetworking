// TNRequest.swift
//
// Copyright © 2018-2020 Vasilis Panagiotopoulos. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// swiftlint:disable type_body_length file_length

import Foundation
import UIKit

// MARK: Custom types
public typealias TNSuccessCallback<T> = (T) -> Void
public typealias TNFailureCallback = (_ error: TNError, _ data: Data?) -> Void

// MARK: Enums
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

/// The the body type of the request
public enum TNRequestBodyType: String {
    /// The request params are sent as application/x-www-form-urlencoded mime type
    case xWWWFormURLEncoded = "application/x-www-form-urlencoded"
    /// The request params are sent as application/json mime type
    case JSON = "application/json"
}

open class TNRequest: TNOperation {
    // MARK: Internal properties

    internal var method: TNMethod!
    internal var currentQueue: TNQueue!
    internal var dataTask: URLSessionDataTask?
    internal var customError: TNError?
    internal var data: Data?
    internal var urlResponse: URLResponse?
    internal var params: [String: Any?]?
    internal var path: String
    internal var pathType: SNPathType = .normal
    internal var mockFilePath: TNPath?

    // MARK: Private properties

    public var configuration: TNConfiguration = TNConfiguration.makeDefaultConfiguration()

    // MARK: Private properties
    private var headers: [String: String]?
    private var environment: TNEnvironment?

    // MARK: Initializers

    /// Initializes a TNRequest request
    ///
    /// parameters:
    ///  - method: The http method of request, e.g. .get, .post, .head, etc.
    ///  - url: The URL of the request
    ///  - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    ///  - params: A Dictionary as request params. If method is .get it automatically appends
    ///     them to url, otherwise it sets them as request body.
    ///  - configuration: A TNConfiguration object
    public init(method: TNMethod,
                url: String,
                headers: [String: String]? = nil,
                params: [String: Any?]? = nil,
                configuration: TNConfiguration? = nil) {
        self.method = method
        self.headers = headers
        self.params = params
        self.pathType = .full
        self.path = url
        self.configuration = configuration ?? TNConfiguration.makeDefaultConfiguration()
    }

    /// Initializes a TNRequest request
    ///
    /// parameters:
    ///  - method: The http method of request, e.g. .get, .post, .head, etc.
    ///  - url: The URL of the request
    ///  - configuration: A TNConfiguration object
    convenience init(method: TNMethod, url: String,
                     configuration: TNConfiguration = TNConfiguration.makeDefaultConfiguration()) {
        self.init(method: method, url: url, headers: nil, params: nil, configuration: configuration)
    }

    /// Initializes a TNRequest request
    ///
    /// - parameters:
    ///     - method: The http method of request, e.g. .get, .post, .head, etc.
    ///     - url: The URL of the request
    ///     - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    convenience init(method: TNMethod, url: String, headers: [String: String]? = nil) {
        self.init(method: method, url: url, headers: nil, params: nil)
    }

    /// Initializes a TNRequest request
    ///
    /// - parameters:
    ///    - method: The http method of request, e.g. .get, .post, .head, etc.
    ///    - url: The URL of the request
    ///    - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    ///    - configuration: A TNConfiguration object
    convenience init(method: TNMethod,
                     url: String,
                     headers: [String: String]? = nil,
                     configuration: TNConfiguration = TNConfiguration.makeDefaultConfiguration()) {
        self.init(method: method, url: url, headers: nil, params: nil, configuration: configuration)
    }

    /// Initializes a TNRequest request
    ///
    /// - parameters:
    ///   - route: a TNRouteProtocol enum value
    public init(route: TNRouterProtocol,
                environment: TNEnvironment? = TNEnvironment.current) {
        let route = route.configure()
        self.method = route.method
        self.headers = route.headers
        self.params = route.params
        self.path = route.path.convertedPath()
        self.environment = environment
        self.mockFilePath = route.mockFilePath

        if let environmentConfiguration = environment?.configuration {
            self.configuration = TNConfiguration.override(configuration: self.configuration,
                                                                 with: environmentConfiguration)
        }
        if let routeConfiguration = route.configuration {
            self.configuration = TNConfiguration.override(configuration: self.configuration,
                                                                 with: routeConfiguration)
        }
    }

    // MARK: Create request

    /// Converts a TNRequest instance to asRequest
    public func asRequest() throws -> URLRequest {

        let urlString = NSMutableString()

        if pathType == .normal {
            guard let currentEnvironment = environment else { throw TNError.environmentNotSet }
            urlString.setString(currentEnvironment.description + "/" + path)
        } else {
            urlString.setString(path)
        }

        // Create query string from the given params
        let queryString = try params?.filter({ $0.value != nil }).map { param -> String in
            if let value = String(describing: param.value!)
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
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

        let defaultCachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        var request = URLRequest(url: url,
                                 cachePolicy: configuration.cachePolicy ?? defaultCachePolicy)

        setHeaders()

        if let timeoutInterval = self.configuration.timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        do {
            try addBodyParams(withRequest: &request,
                          queryString: queryString)
        } catch {
            throw TNError.invalidParams
        }

        // Set http method
        request.httpMethod = method.rawValue

        return request
    }

    /// Cancels a TNRequest started request
    open override func cancel() {
        super.cancel()
        dataTask?.cancel()
    }

    // MARK: Helper methods

    fileprivate func addBodyParams(withRequest request: inout URLRequest,
                                   queryString: String?) throws {
        // Set body params if method is not get
        if method != TNMethod.get {
            let requestBodyType = configuration.requestBodyType ?? .xWWWFormURLEncoded

            request.addValue(requestBodyType.rawValue, forHTTPHeaderField: "Content-Type")

            if requestBodyType == .xWWWFormURLEncoded {
                request.httpBody = queryString?.data(using: .utf8)
            } else {
                do {
                    let jsonData = try  handleMiddlewareBodyBeforeSendIfNeeded(params: params)?.toJSONData()
                    request.httpBody = jsonData
                } catch {
                    throw TNError.invalidParams
                }
            }
        }
    }

    internal func sessionDataTask(request: URLRequest, completionHandler: ((Data) -> Void)?,
                                  onFailure: TNFailureCallback?) -> URLSessionDataTask {

        /// Create mock request if needed
        if shouldMockRequest() {
            return createMockRequest(request: request,
                                     completionHandler:
                completionHandler, onFailure: onFailure)
        }

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: TNSession(withTNRequest: self),
                                 delegateQueue: OperationQueue.current)

        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            var statusCode: Int?
            self.data = data
            self.urlResponse = urlResponse

            /// Error handling
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    self.customError = TNError.cancelled(error)
                } else {
                    self.customError = TNError.networkError(error)
                }
            } else if let response = urlResponse as? HTTPURLResponse {
                statusCode = response.statusCode as Int?

                if let statusCode = statusCode, statusCode / 100 != 2 {
                    self.customError = TNError.notSuccess(statusCode)
                }
            }

            if let customError = self.customError {
                DispatchQueue.main.async {
                    TNLog.logRequest(request: self)
                    onFailure?(customError, data)
                    self.handleDataTaskFailure()
                }
            } else {
                completionHandler?(data ?? Data())
            }
        }

        return dataTask
    }

    fileprivate func setHeaders() {
        /// Merge headers with the following order environment > route > request
        if headers == nil {
            headers = [:]
        }

        headers?.merge(configuration.headers, uniquingKeysWith: { (old, _) in old })

        headers = handleMiddlewareHeadersBeforeSendIfNeeded(headers: headers)
    }

    internal func shouldMockRequest() -> Bool {
        return self.configuration.useMockData
    }

    fileprivate func createMockRequest(request: URLRequest,
                                       completionHandler: ((Data) -> Void)?,
                                       onFailure: TNFailureCallback?) -> URLSessionDataTask {
        let fakeSession = URLSession(configuration: URLSession.shared.configuration)
                            .dataTask(with: request)

        guard let filePath = mockFilePath?.convertedPath() else {
            onFailure?(.invalidMockData(path), nil)
            return fakeSession
        }

        if  let filenameWithExt = filePath.components(separatedBy: "/").last,
            let subdirectory = filePath.components(separatedBy: "/").first,
            let filename = filenameWithExt.components(separatedBy: ".").first,
            let url = configuration.mockDataBundle?.url(forResource: filename,
                                                        withExtension: filenameWithExt
                                                            .components(separatedBy: ".").last,
                                                        subdirectory: subdirectory,
                                                        localization: nil),
            let data = try? Data(contentsOf: url) {
            self.data = data
            completionHandler?(data)
        } else {
            onFailure?(.invalidMockData(path), nil)
        }

        return fakeSession
    }

    // MARK: Operation
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

    /// Adds a request to a queue and starts it's execution. The response object in success callback is of
    /// type Decodable
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
    public func start<T: Decodable>(queue: TNQueue? = TNQueue.shared,
                                    responseType: T.Type,
                                    onSuccess: TNSuccessCallback<T>?,
                                    onFailure: TNFailureCallback?) {
        currentQueue = queue ?? TNQueue.shared
        currentQueue.beforeOperationStart(request: self)

        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            if let error = error as? TNError {
                onFailure?(error, nil)
            }
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

            TNLog.logRequest(request: self)
            onSuccess?(object)
            self.handleDataTaskCompleted()
        }, onFailure: { error, data in
            onFailure?(error, data)
            self.handleDataTaskFailure()
        })

        currentQueue.addOperation(self)
    }

    /// Adds a request to a queue and starts it's execution. The response object in success callback is of type UIImage
    ///
    /// - parameters:
    ///     - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///     - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///     - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
    public func start<T: UIImage>(queue: TNQueue? = TNQueue.shared,
                                  responseType: T.Type,
                                  onSuccess: TNSuccessCallback<T>?,
                                  onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)

        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            if let error = error as? TNError {
                onFailure?(error, nil)
            }
            self.handleDataTaskFailure()
            return
        }

        dataTask = sessionDataTask(request: request, completionHandler: { data in
            let image = T(data: data)

            if image == nil {
                self.customError = .responseInvalidImageData
                TNLog.logRequest(request: self)

                onFailure?(.responseInvalidImageData, data)
                self.handleDataTaskFailure()
            } else {
                TNLog.logRequest(request: self)
                onSuccess?(image!)
                self.handleDataTaskCompleted()
            }
        }, onFailure: { error, data in
            onFailure?(error, data)
            self.handleDataTaskFailure()
        })

        currentQueue.addOperation(self)
    }

    /// Adds a request to a queue and starts it's execution. The response object in success callback is of type String
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
    public func start(queue: TNQueue? = TNQueue.shared,
                      responseType: String.Type,
                      onSuccess: TNSuccessCallback<String>?,
                      onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)

        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            if let error = error as? TNError {
                onFailure?(error, nil)
            }
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

    /// Adds a request to a queue and starts it's execution. The response object in success callback is of type Data
    ///
    /// - parameters:
    ///     - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///     - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///     - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
    public func start(queue: TNQueue? = TNQueue.shared,
                      responseType: Data.Type,
                      onSuccess: TNSuccessCallback<Data>?,
                      onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)

        let request: URLRequest!
        do {
            request = try asRequest()
        } catch let error {
            if let error = error as? TNError {
                onFailure?(error, nil)
            }
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
