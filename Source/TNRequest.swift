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

/// Custom type for success data task.
public typealias TNSuccessCallback<T> = (T) -> Void
/// Custom type for failure data task.
public typealias TNFailureCallback = (_ error: TNError, _ data: Data?) -> Void

// MARK: Enums
/// The HTTP request method based on specification of https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html.
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

/// The core class of TermiNetwork. It uses all
open class TNRequest: TNOperation {
    // MARK: Internal properties

    internal var method: TNMethod!
    internal var currentQueue: TNQueue!
    internal var dataTask: URLSessionTask?
    //internal var urlResponse: URLResponse?
    internal var params: [String: Any?]?
    internal var path: String
    internal var pathType: SNPathType = .relative
    internal var mockFilePath: TNPath?
    internal var multipartBoundary: String?
    internal var multipartFormDataStream: TNMultipartFormDataStream?

    // MARK: Public properties

    /// The configuration of the request. This will be merged with  environment configuration and will override
    /// values if needed.
    public var configuration: TNConfiguration = TNConfiguration.makeDefaultConfiguration()

    // MARK: Private properties
    private var headers: [String: String]?
    private var environment: TNEnvironment?

    // MARK: Initializers

    /// Initializes a TNRequest request.
    ///
    /// parameters:
    ///  - method: The http method of request, e.g. .get, .post, .head, etc.
    ///  - url: The URL of the request.
    ///  - headers: A Dictionary of header values, etc. ["Content-type": "text/html"] (optional)
    ///  - params: A Dictionary as request params. If method is .get, it automatically appends
    ///     them to url, otherwise it is seting them as request body.
    ///  - configuration: A TNConfiguration object.
    public init(method: TNMethod,
                url: String,
                headers: [String: String]? = nil,
                params: [String: Any?]? = nil,
                configuration: TNConfiguration? = nil) {
        self.method = method
        self.headers = headers
        self.params = params
        self.pathType = .absolute
        self.path = url
        self.configuration = configuration ?? TNConfiguration.makeDefaultConfiguration()
    }

    /// Initializes a TNRequest request.
    ///
    /// parameters:
    ///  - method: The http method of request, e.g. .get, .post, .head, etc.
    ///  - url: The URL of the request.
    ///  - configuration: A TNConfiguration object.
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
    internal init(route: TNRouteProtocol,
                  environment: TNEnvironment? = TNEnvironment.current,
                  configuration: TNConfiguration? = nil) {
        let route = route.configure()
        self.method = route.method
        self.headers = route.headers
        self.params = route.params
        self.path = route.path.convertedPath
        self.environment = environment
        self.mockFilePath = route.mockFilePath

        if let environmentConfiguration = environment?.configuration {
            self.configuration = TNConfiguration.override(configuration: self.configuration,
                                                                 with: environmentConfiguration)
        }
        if let routerConfiguration = configuration {
            self.configuration = TNConfiguration.override(configuration: self.configuration,
                                                                 with: routerConfiguration)
        }
        if let routeConfiguration = route.configuration {
            self.configuration = TNConfiguration.override(configuration: self.configuration,
                                                                 with: routeConfiguration)
        }
    }

    public convenience init(route: TNRouteProtocol,
                            environment: TNEnvironment? = TNEnvironment.current) {
        self.init(route: route,
                  environment: environment,
                  configuration: nil)
    }

    // MARK: Public methods

    /// Converts a TNRequest instance to asRequest
    public func asRequest() throws -> URLRequest {
        let params = try handleMiddlewareBodyBeforeSendIfNeeded(params: self.params)
        let urlString = NSMutableString()

        if pathType == .relative {
            guard let currentEnvironment = environment else { throw TNError.environmentNotSet }
            urlString.setString(currentEnvironment.description + "/" + path)
        } else {
            urlString.setString(path)
        }

        // Append query string to url in case of .get method
        if let params = params, method == .get {
            try urlString.append("?" + TNRequestBodyGenerators.generateUrlEncodedString(with: params))
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

        // Set http method
        request.httpMethod = method.rawValue

        return request
    }

    /// Cancels a request
    open override func cancel() {
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
        if method != TNMethod.get {
            let requestBodyType = configuration.requestBodyType ??
                TNConfiguration.makeDefaultConfiguration().requestBodyType!

            /// Add header for coresponding body type
            request.addValue(requestBodyType.value(), forHTTPHeaderField: "Content-Type")

            if case .multipartFormData = requestBodyType, let boundary = self.multipartBoundary,
                let multipartParams = params as? [String: TNMultipartFormDataPartType] {
                let contentLength = String(try TNMultipartFormDataHelpers.contentLength(forParams: multipartParams,
                                                                                        boundary: boundary))
                request.addValue(contentLength, forHTTPHeaderField: "Content-Length")
            }

            switch requestBodyType {
            case .xWWWFormURLEncoded:
                request.httpBody = try TNRequestBodyGenerators.generateUrlEncodedString(with: params)
                                        .data(using: .utf8)
            case .JSON:
                request.httpBody = try TNRequestBodyGenerators.generateJSONBodyData(with: params)
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
    open override func start() {
        _executing = true
        _finished = false
        dataTask?.resume()
    }

    func handleDataTaskCompleted(with data: Data?,
                                 urlResponse: URLResponse?,
                                 tnError: TNError?) {
        _executing = false
        _finished = true

        currentQueue.afterOperationFinished(request: self,
                                            data: data,
                                            response: urlResponse,
                                            tnError: tnError)
    }

    func handleDataTaskFailure(with data: Data?,
                               urlResponse: URLResponse?,
                               tnError: TNError?) {
        switch currentQueue.failureMode {
        case .continue:
            break
        case .cancelAll:
            currentQueue.cancelAllOperations()
        }

        _executing = false
        _finished = true

        currentQueue.afterOperationFinished(request: self,
                                            data: data,
                                            response: urlResponse,
                                            tnError: tnError)
    }
}
