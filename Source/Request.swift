// Request.swift
//
// Copyright © 2018-2021 Vasilis Panagiotopoulos. All rights reserved.
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

/// Custom type for success data task.
public typealias SuccessCallback<T> = (T) -> Void
/// Custom type for download success data task.
public typealias DownloadSuccessCallback = () -> Void
/// Custom type for failure data task.
public typealias FailureCallback = (_ error: TNError, _ data: Data?) -> Void

// MARK: Enums
/// The HTTP request method based on specification of https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html.
public enum Method: String {
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

/// Internal type for figuring out the type of the request
internal enum RequestType {
    case data
    case upload
    case download(String)
}

/// The core class of TermiNetwork. It handles the request creation and its execution.
public final class Request: Operation {
    // MARK: Internal properties

    internal var method: Method!
    internal var currentQueue: Queue!
    internal var dataTask: URLSessionTask?
    internal var path: String!
    internal var pathType: SNPathType = .relative
    internal var mockFilePath: Path?
    internal var multipartBoundary: String?
    internal var multipartFormDataStream: MultipartFormDataStream?
    internal var requestType: RequestType = .data
    internal var urlRequestLogInitiated: Bool = false
    internal var responseHeadersClosure: ((URLResponse?) -> Void)?
    internal var processedHeaders: [String: String]?
    internal var pinningErrorOccured: Bool = false
    /// The start date of the request.
    internal var startedAt: Date?
    /// The duration of the request.
    internal var duration: TimeInterval?
    /// Interceptors chain
    internal var interceptors: [InterceptorProtocol]?
    /// Hold the success completion handler of each start method,
    /// needed by interceptor retry action.
    internal var successCompletionHandler: ((Data, URLResponse?) -> Void)?
    internal var progressCallback: ProgressCallbackType?
    internal var urlRequest: URLRequest?
    internal var urlResponse: URLResponse?
    internal var skipLogOnComplete: Bool = false

    // MARK: Public properties

    /// The configuration of the request. This will be merged with the environment configuration if needed.
    public var configuration: Configuration = Configuration.makeDefaultConfiguration()
    /// The number of the retries initiated by interceptor.
    public var retryCount: Int = 0
    /// The environment of the request.
    public var environment: Environment?
    /// An associated object with the request. Use this variable to optionaly assign an object to it, for later use.
    public var associatedObject: AnyObject?
    /// The headers of the request.
    public var headers: [String: String]?
    /// The parameters of the request.
    public var params: [String: Any?]?

    // MARK: Initializers
    /// Default initializer
    override init() {
        super.init()
    }

    /// Initializes a Request.
    ///
    /// - parameters:
    ///   - method: A Method to use, for example: .get, .post, etc.
    ///   - url: The URL of the request.
    ///   - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    ///   - params: The parameters of the request. (optional)
    ///   - configuration: A configuration object (optional, e.g. if you want ot use custom
    ///   configuration for the request).
    public init(method: Method,
                url: String,
                headers: [String: String]? = nil,
                params: [String: Any?]? = nil,
                configuration: Configuration? = nil) {
        self.method = method
        self.headers = headers
        self.params = params
        self.pathType = .absolute
        self.path = url
        self.configuration = configuration ?? Configuration.makeDefaultConfiguration()
    }

    /// Initializes a Request.
    ///
    /// - parameters:
    ///     - method: The method of request, e.g. .get, .post, .head, etc.
    ///     - url: The URL of the request
    ///     - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    convenience init(method: Method,
                     url: String,
                     headers: [String: String]? = nil) {
        self.init(method: method, url: url, headers: nil, params: nil)
    }

    /// Initializes a Request.
    ///
    /// - parameters:
    ///    - method: The method of request, e.g. .get, .post, .head, etc.
    ///    - url: The URL of the request
    ///    - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    ///    - configuration: A Configuration object
    convenience init(method: Method,
                     url: String,
                     headers: [String: String]? = nil,
                     configuration: Configuration = Configuration.makeDefaultConfiguration()) {
        self.init(method: method, url: url, headers: nil, params: nil, configuration: configuration)
    }

    /// Initializes a Request.
    ///
    /// - parameters:
    ///   - route: a RouteProtocol enum value
    internal init(route: RouteProtocol,
                  environment: Environment? = Environment.current,
                  configuration: Configuration? = nil) {
        let route = route.configure()
        self.method = route.method
        self.headers = route.headers
        self.params = route.params
        self.path = route.path.convertedPath
        self.environment = environment
        self.mockFilePath = route.mockFilePath

        if let environmentConfiguration = environment?.configuration {
            self.configuration = Configuration.override(left: self.configuration,
                                                        right: environmentConfiguration)
        }
        if let routerConfiguration = configuration {
            self.configuration = Configuration.override(left: self.configuration,
                                                        right: routerConfiguration)
        }
        if let routeConfiguration = route.configuration {
            self.configuration = Configuration.override(left: self.configuration,
                                                        right: routeConfiguration)
        }
    }

    /// Initializes a Request.
    ///
    /// - parameters:
    ///   - route: a RouteProtocol enum value
    ///   - environment: Specifies a different environment to use than the global setted environment.
    public convenience init(route: RouteProtocol,
                            environment: Environment? = Environment.current) {
        self.init(route: route,
                  environment: environment,
                  configuration: nil)
    }

    // MARK: Public methods

    /// Converts a Request instance an URLRequest instance.
    public func asRequest() throws -> URLRequest {
        let params = try handleMiddlewareParamsIfNeeded(params: self.params)
        let urlString = NSMutableString()

        if pathType == .relative {
            guard let currentEnvironment = environment else { throw TNError.environmenotSet }
            urlString.setString(currentEnvironment.stringURL + "/" + path)
        } else {
            urlString.setString(path)
        }

        // Append query string to url in case of .get method
        if let params = params, method == .get {
            try urlString.append("?" + RequestBodyGenerator.generateURLEncodedString(with: params))
        }

        guard let url = URL(string: urlString as String) else {
            throw TNError.invalidURL
        }

        let defaultCachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        var request = URLRequest(url: url,
                                 cachePolicy: configuration.cachePolicy ?? defaultCachePolicy)

        try setHeaders()

        if let timeoutInterval = self.configuration.timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        try addBodyParamsIfNeeded(withRequest: &request,
                                  params: params)

        // Set http method.
        request.httpMethod = method.rawValue

        // Hold reference to request.
        urlRequest = request

        return request
    }

    /// Cancels a request
    public override func cancel() {
        super.cancel()
        dataTask?.cancel()
    }

    // MARK: Helper methods

    fileprivate func addBodyParamsIfNeeded(withRequest request: inout URLRequest,
                                           params: [String: Any?]?) throws {

        guard let params = params else {
            return
        }

        // Set body params if method is not get
        if method != Method.get {
            let requestBodyType = configuration.requestBodyType ??
                Configuration.makeDefaultConfiguration().requestBodyType!

            /// Add header for coresponding body type
            request.addValue(requestBodyType.value(), forHTTPHeaderField: "Content-Type")

            if case .multipartFormData = requestBodyType, let boundary = self.multipartBoundary,
                let multipartParams = params as? [String: MultipartFormDataPartType] {
                let contentLength = String(try MultipartFormDataHelpers.contentLength(forParams: multipartParams,
                                                                                        boundary: boundary))
                request.addValue(contentLength, forHTTPHeaderField: "Content-Length")
            }

            switch requestBodyType {
            case .xWWWFormURLEncoded:
                request.httpBody = try RequestBodyGenerator.generateURLEncodedString(with: params)
                                        .data(using: .utf8)
            case .JSON:
                request.httpBody = try RequestBodyGenerator.generateJSONBodyData(with: params)
            default:
                break
            }
        }
    }

    fileprivate func setHeaders() throws {
        /// Merge headers with the following order environment > route > request
        if headers == nil {
            headers = [:]
        }

        headers?.merge(configuration.headers ?? [:], uniquingKeysWith: { (old, _) in old })

        headers = try handleMiddlewareHeadersBeforeSendIfNeeded(headers: headers)
    }

    // MARK: Operation

    /// Overrides the start() function from Operation class.
    /// You should never call this function directly. If you want to start a request without callbacks
    /// use startEmpty() instead.
    public override func start() {
        // Prevent from calling this function directly.
        guard dataTask != nil else {
            fatalError("You should never call start() directly, use startEmpty() instead.")
        }

        currentQueue.beforeEachRequestCallback?(self)
        initializeInterceptorsChainIfNeeded()

        _executing = true
        _finished = false
        startedAt = Date()

        Log.logRequest(request: self,
                       data: nil,
                       state: .started,
                       error: nil)

        dataTask?.resume()
    }

    ///
    /// Starts a request without callbacks.
    /// - parameters:
    ///     - queue: A Queue instance. If no queue is specified it uses the default one.
    public func startEmpty(_ queue: Queue? = nil) -> Request {
        currentQueue = queue ?? Queue.shared
        dataTask = SessionTaskFactory.makeDataTask(with: self,
                                                   completionHandler: { data, urlResponse in
            self.handleDataTaskCompleted(with: data,
                                         urlResponse: urlResponse)
        }, onFailure: { error, data in
            self.handleDataTaskCompleted(with: data,
                                         error: error)
        })

        currentQueue.addOperation(self)
        return self
    }

    func handleDataTaskCompleted(with data: Data?,
                                 urlResponse: URLResponse? = nil,
                                 error: TNError? = nil,
                                 onSuccessCallback: (() -> Void)? = nil,
                                 onFailureCallback: (() -> Void)? = nil) {
        self.processNextInterceptorIfNeeded(
            data: data,
            error: error) { processedData, processedError in
            if let error = processedError {
                self.handleDataTaskFailure(with: processedData,
                                           urlResponse: urlResponse,
                                           error: error,
                                           onFailure: onFailureCallback ?? {})
            } else {
                self.handleDataTaskSuccess(with: processedData,
                                           urlResponse: urlResponse,
                                           onSuccess: onSuccessCallback ?? {})
            }
        }
    }

    func handleDataTaskSuccess(with data: Data?,
                               urlResponse: URLResponse?,
                               onSuccess: @escaping (() -> Void)) {
        onSuccess()

        self.duration = self.startedAt?.distance(to: Date())
        self.responseHeadersClosure?(urlResponse)

        if !skipLogOnComplete {
            Log.logRequest(request: self,
                           data: data,
                           state: .finished,
                           error: nil)
        }

        self._executing = false
        self._finished = true

        self.currentQueue.afterOperationFinished(request: self,
                                                 data: data,
                                                 response: urlResponse,
                                                 tnError: nil)
    }

    func handleDataTaskFailure(with data: Data?,
                               urlResponse: URLResponse?,
                               error: TNError,
                               onFailure: @escaping () -> Void) {
        onFailure()

        self.responseHeadersClosure?(urlResponse)

        switch self.currentQueue.failureMode {
        case .continue:
            break
        case .cancelAll:
            self.currentQueue.cancelAllOperations()
        }

        self._executing = false
        self._finished = true

        self.currentQueue.afterOperationFinished(request: self,
                                                 data: data,
                                                 response: urlResponse,
                                                 tnError: error)
        if !skipLogOnComplete {
            Log.logRequest(request: self,
                           data: data,
                           error: error)
        }
    }
}
