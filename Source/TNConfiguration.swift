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

public class TNConfiguration {
    public var cachePolicy: URLRequest.CachePolicy?
    public var timeoutInterval: TimeInterval?
    public var requestBodyType: TNRequestBodyType?
    public var certificateData: NSData?
    public var verbose: Bool = false
    public var headers: [String: String] = [:]
    public var mockDataBundle: Bundle?
    public var useMockData: Bool = false

    public init() { }

    public init(cachePolicy: URLRequest.CachePolicy?,
                timeoutInterval: TimeInterval?,
                requestBodyType: TNRequestBodyType?,
                certificatePath: String? = nil,
                verbose: Bool = false,
                headers: [String: String] = [:],
                mockDataBundle: Bundle? = nil,
                useMockData: Bool = false) {
        self.cachePolicy = cachePolicy ?? TNConfiguration.makeDefaultConfiguration()
                            .cachePolicy
        self.timeoutInterval = timeoutInterval ?? TNConfiguration.makeDefaultConfiguration()
                            .timeoutInterval
        self.requestBodyType = requestBodyType ?? TNConfiguration.makeDefaultConfiguration()
                            .requestBodyType
        self.verbose = verbose
        self.headers = headers
        self.mockDataBundle = mockDataBundle
        self.useMockData = useMockData

        if let certPath = certificatePath {
            setCertificateData(with: certPath)
        }
    }

    public convenience init(cachePolicy: URLRequest.CachePolicy?) {
        self.init(cachePolicy: cachePolicy,
                  timeoutInterval: nil,
                  requestBodyType: nil)
    }

    public convenience init(timeoutInterval: TimeInterval?) {
        self.init(cachePolicy: nil,
                  timeoutInterval: timeoutInterval,
                  requestBodyType: nil)
    }

    public convenience init(requestBodyType: TNRequestBodyType?) {
        self.init(cachePolicy: nil,
                  timeoutInterval: nil,
                  requestBodyType: requestBodyType)
    }

    public convenience init(certificatePath name: String) {
        self.init(cachePolicy: nil,
                  timeoutInterval: nil,
                  requestBodyType: nil,
                  certificatePath: name)
    }

    public func setCertificateData(with path: String) {
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

public extension TNConfiguration {
    static func makeDefaultConfiguration() -> TNConfiguration {
        return TNConfiguration(cachePolicy: .useProtocolCachePolicy,
                                      timeoutInterval: 60,
                                      requestBodyType: .xWWWFormURLEncoded)
    }

    static func override(configuration: TNConfiguration,
                         with overrideConfiguration: TNConfiguration)
                -> TNConfiguration {

        let clone = configuration.copy() as? TNConfiguration ?? TNConfiguration()
        clone.cachePolicy = overrideConfiguration.cachePolicy
        clone.timeoutInterval = overrideConfiguration.timeoutInterval
        clone.requestBodyType = overrideConfiguration.requestBodyType
        clone.certificateData = overrideConfiguration.certificateData
        clone.verbose = overrideConfiguration.verbose
        clone.headers.merge(overrideConfiguration.headers, uniquingKeysWith: { (_, new) in new })
        clone.mockDataBundle = overrideConfiguration.mockDataBundle
        clone.useMockData = overrideConfiguration.useMockData

        return clone
    }
}
