// Configuration.swift
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

/// Type for mock delay randomizer.
/// - parameters:
///   - min: The lower bound of interval.
///   - max: The upper bound of interval.
public typealias MockDelayType = (min: TimeInterval, max: TimeInterval)

/// A configuration class that can be used with Environment, RouteConfiguration and Request.
/// A configuration object follows the following rules:
/// 1. When a Configuration object is passed to a Environment,
/// each Router (with its routes) will inherit this configuration.
/// 2. When a Configuration object is passed to Router, all its routes will inherit this configuration.
public final class Configuration {
    // MARK: Public properties

    /// The cache policy of the request.
    public var cachePolicy: URLRequest.CachePolicy?
    /// The timeout interval of the request.
    public var timeoutInterval: TimeInterval?
    /// The request body type of the request. Can be either .xWWWFormURLEncoded or .JSON.
    public var requestBodyType: RequestBodyType?
    /// The certificate file paths used for certificate pining.
    public var certificatePaths: [String]? {
        didSet {
            if let certPaths = certificatePaths {
                setCertificateData(with: certPaths)
            }
        }
    }
    /// Enables or disables debug mode.
    public var verbose: Bool?
    /// Additional headers of the request. They will be merged with the headers specified in RouteConfiguration.
    public var headers: [String: String]?
    /// The Bundle object of mock data used when useMockData is true.
    public var mockDataBundle: Bundle?
    /// Enables or disables request mocking.
    public var mockDataEnabled: Bool?
    /// Specifies a delay when mock data is used.
    public var mockDelay: MockDelayType?
    /// Specifies a key decoding strategy. Take a look
    /// at: https://developer.apple.com/documentation/foundation/jsondecoder/keydecodingstrategy
    public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?
    /// Error handlers that will be used as a fallback after request failure.
    public var interceptors: [InterceptorProtocol.Type]?
    /// Request middlewares
    public var requestMiddlewares: [RequestMiddlewareProtocol.Type]?

    // MARK: Internal properties

    /// The certificate data when certificate pinning is enabled.
    internal var certificateData: [NSData]?
    /// Skip Interceptors for being executed
    internal var skipInterceptors = false

    // MARK: Initializers

    /// Default initializer of Configuration
    /// - parameters:
    ///     - cachePolicy: The cache policy of the request.
    ///     - timeoutInterval: The timeout interval of the request.
    ///     - requestBodyType: The request body type of the request. Can be either .xWWWFormURLEncoded or .JSON.
    ///     - certificatePaths: The certificate file paths used for certificate pining.
    ///     - verbose: Enables or disables debug mode.
    ///     - headers: Additional headers of the request. Will be merged with the headers specified
    ///         in RouteConfiguration.
    ///     - mockDataBundle: The Bundle object of mock data used when useMockData is true.
    ///     - mockDataEnabled: Enables or disables request mocking.
    ///     - mockDelay: Specifies a delay when mock data is used.
    ///     - keyDecodingStrategy: // Specifies a key decoding strategy. Take a look,
    ///         at: https://developer.apple.com/documentation/foundation/jsondecoder/keydecodingstrategy
    ///     - errorHandlers: Error handlers that will be used as a fallback after request failure.
    ///     - requestMiddlewares: Request middlewares. For example see
    ///         Examples/Communication/Middlewares/CryptoMiddleware.swift
    public init(cachePolicy: URLRequest.CachePolicy? = nil,
                timeoutInterval: TimeInterval? = nil,
                requestBodyType: RequestBodyType? = nil,
                certificatePaths: [String]? = nil,
                verbose: Bool? = nil,
                headers: [String: String]? = nil,
                mockDataBundle: Bundle? = nil,
                mockDataEnabled: Bool? = nil,
                mockDelay: MockDelayType? = nil,
                keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil,
                interceptors: [InterceptorProtocol.Type]? = nil,
                requestMiddlewares: [RequestMiddlewareProtocol.Type]? = nil) {

        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.requestBodyType = requestBodyType
        self.verbose = verbose
        self.headers = headers
        self.mockDataBundle = mockDataBundle
        self.mockDataEnabled = mockDataEnabled
        self.mockDelay = mockDelay
        self.keyDecodingStrategy = keyDecodingStrategy
        self.interceptors = interceptors
        self.requestMiddlewares = requestMiddlewares

        if let certPaths = certificatePaths {
            setCertificateData(with: certPaths)
        }
    }

    // MARK: Internal methods

    internal func setCertificateData(with paths: [String]) {
        self.certificateData = paths.count > 0 ? [] : nil
        paths.forEach { path in
            if let certData = NSData(contentsOfFile: path) {
                self.certificateData?.append(certData)
            } else {
                Log.printSimpleErrorIfNeeded(TNError.invalidCertificatePath(path))
            }
        }
    }
}

extension Configuration: NSCopying {
    /// NSCopying implementation, used for cloning Configuration objects.
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = Configuration()
        configuration.cachePolicy = cachePolicy
        configuration.timeoutInterval = timeoutInterval
        configuration.requestBodyType = requestBodyType
        configuration.certificatePaths = certificatePaths
        configuration.certificateData = certificateData
        configuration.verbose = verbose
        configuration.headers = headers
        configuration.mockDataBundle = mockDataBundle
        configuration.mockDelay = mockDelay
        configuration.mockDataEnabled = mockDataEnabled
        configuration.keyDecodingStrategy = keyDecodingStrategy
        configuration.interceptors = interceptors
        configuration.requestMiddlewares = requestMiddlewares
        return configuration
    }
}

extension Configuration {
    /// Generates a default configuration
    static func makeDefaultConfiguration() -> Configuration {
        return Configuration(cachePolicy: .useProtocolCachePolicy,
                               timeoutInterval: 60,
                               requestBodyType: .xWWWFormURLEncoded,
                               verbose: false,
                               headers: [:],
                               mockDataBundle: nil,
                               mockDataEnabled: false,
                               mockDelay: MockDelayType(min: 0.01, max: 0.07))
    }

    // swiftlint:disable cyclomatic_complexity
    static func override(left: Configuration,
                         right: Configuration)
                -> Configuration {

        let leftClone = left.copy() as? Configuration ?? Configuration()

        if let cachePolicy = right.cachePolicy {
            leftClone.cachePolicy = cachePolicy
        }
        if let timeoutInterval = right.timeoutInterval {
            leftClone.timeoutInterval = timeoutInterval
        }
        if let requestBodyType = right.requestBodyType {
            leftClone.requestBodyType = requestBodyType
        }
        if let certificatePaths = right.certificatePaths {
            leftClone.certificatePaths = certificatePaths
        }
        if let certificateData = right.certificateData {
            leftClone.certificateData = certificateData
        }
        if let verbose = right.verbose {
            leftClone.verbose = verbose
        }

        // Merge headers
        var cloneHeaders = leftClone.headers ?? [:]
        let headers = right.headers ?? [:]
        cloneHeaders.merge(headers, uniquingKeysWith: { (_, new) in new })
        leftClone.headers = cloneHeaders

        if let mockDataBundle = right.mockDataBundle {
            leftClone.mockDataBundle = mockDataBundle
        }
        if let mockDataEnabled = right.mockDataEnabled {
            leftClone.mockDataEnabled = mockDataEnabled
        }
        if let mockDelay = right.mockDelay {
            leftClone.mockDelay = mockDelay
        }
        if let requestMiddlewares = right.requestMiddlewares {
            leftClone.requestMiddlewares = requestMiddlewares
        }
        if let keyDecodingStrategy = right.keyDecodingStrategy {
            leftClone.keyDecodingStrategy = keyDecodingStrategy
        }
        if let interceptors = right.interceptors {
            leftClone.interceptors = interceptors
        }
        return leftClone
    }
}
