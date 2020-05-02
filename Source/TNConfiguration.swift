// TNEnvironment.swift
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

import Foundation

/// Type for mock delay randomizer
public typealias TNMockDelayType = (min: TimeInterval, max: TimeInterval)

/// A generic configuration class that can be used with TNEnvironment, TNRouteConfiguration and TNRequest.
/// If a TNConfiguration is passed to a TNEnvironment, each TNRequest will inherit this configuration.
/// Also, each request can have its own TNConfiguration whose settings will override those from environment.
public class TNConfiguration {
    // MARK: Public properties

    /// The cache policy of the request.
    public var cachePolicy: URLRequest.CachePolicy?
    /// The timeout interval of the request.
    public var timeoutInterval: TimeInterval?
    /// The request body type of the request. Can be either .xWWWFormURLEncoded or .JSON.
    public var requestBodyType: TNRequestBodyType?
    /// The certificate data when certificate pinning is enabled.
    public var certificateData: NSData?
    /// Enables or disables debug mode.
    public var verbose: Bool?
    /// Additional headers of the request. Those headers will be merged with those of TNRouteConfiguration.
    public var headers: [String: String]?
    /// The Bundle object of mock data used when useMockData is true.
    public var mockDataBundle: Bundle?
    /// Enables or disables  request mocking.
    public var useMockData: Bool?
    /// Specifies a delay when mock data is used.
    public var mockDelay: TNMockDelayType?

    /// Request middlewares
    public var requestMiddlewares: [TNRequestMiddlewareProtocol]?

    // MARK: Initializers

    public init(cachePolicy: URLRequest.CachePolicy? = nil,
                timeoutInterval: TimeInterval? = nil,
                requestBodyType: TNRequestBodyType? = nil,
                certificatePath: String? = nil,
                verbose: Bool? = nil,
                headers: [String: String]? = nil,
                mockDataBundle: Bundle? = nil,
                useMockData: Bool? = nil,
                mockDelay: TNMockDelayType? = nil) {

        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.requestBodyType = requestBodyType
        self.verbose = verbose
        self.headers = headers
        self.mockDataBundle = mockDataBundle
        self.useMockData = useMockData
        self.mockDelay = mockDelay

        if let certPath = certificatePath {
            setCertificateData(with: certPath)
        }
    }

    // MARK: Internal methods

    internal func setCertificateData(with path: String) {
        if let certData = NSData(contentsOfFile: path) {
            self.certificateData = certData
        } else {
            assertionFailure(String(format: "Certificate not found in %@!", path))
        }
    }
}

extension TNConfiguration: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = TNConfiguration()
        configuration.cachePolicy = cachePolicy
        configuration.timeoutInterval = timeoutInterval
        configuration.requestBodyType = requestBodyType
        configuration.certificateData = certificateData
        configuration.verbose = verbose
        configuration.headers = headers
        return configuration
    }
}

extension TNConfiguration {
    static func makeDefaultConfiguration() -> TNConfiguration {
        return TNConfiguration(cachePolicy: .useProtocolCachePolicy,
                               timeoutInterval: 60,
                               requestBodyType: .xWWWFormURLEncoded,
                               verbose: false,
                               headers: [:],
                               mockDataBundle: nil,
                               useMockData: false,
                               mockDelay: TNMockDelayType(min: 0.01, max: 0.07))
    }

    static func override(configuration: TNConfiguration,
                         with overrideConfiguration: TNConfiguration)
                -> TNConfiguration {

        let clone = configuration.copy() as? TNConfiguration ?? TNConfiguration()

        if let cachePolicy = overrideConfiguration.cachePolicy {
            clone.cachePolicy = cachePolicy
        }
        if let timeoutInterval = overrideConfiguration.timeoutInterval {
            clone.timeoutInterval = timeoutInterval
        }
        if let requestBodyType = overrideConfiguration.requestBodyType {
            clone.requestBodyType = requestBodyType
        }
        if let certificateData = overrideConfiguration.certificateData {
            clone.certificateData = certificateData
        }
        if let verbose = overrideConfiguration.verbose {
            clone.verbose = verbose
        }
        if var cloneHeaders = clone.headers,
            let headers = overrideConfiguration.headers {
            cloneHeaders.merge(headers, uniquingKeysWith: { (_, new) in new })
            clone.headers = cloneHeaders
        } else {
            clone.headers = overrideConfiguration.headers
        }
        if let mockDataBundle = overrideConfiguration.mockDataBundle {
            clone.mockDataBundle = mockDataBundle
        }
        if let useMockData = overrideConfiguration.useMockData {
            clone.useMockData = useMockData
        }
        if let mockDelay = overrideConfiguration.mockDelay {
            clone.mockDelay = mockDelay
        }
        if let requestMiddlewares = overrideConfiguration.requestMiddlewares {
            clone.requestMiddlewares = requestMiddlewares
        }

        return clone
    }
}
