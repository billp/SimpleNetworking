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

public protocol TNEnvironmentProtocol {
    func configure() -> TNEnvironment
}

public enum TNURLScheme: String {
    case http
    case https
}

open class TNEnvironment {
    // MARK: - Properties
    var scheme: TNURLScheme
    var host: String
    var port: Int?
    var suffix: TNPath?
    var configuration: TNRequestConfiguration?

    // MARK: - Static members
    public static var current: TNEnvironment!

    public static func set(_ environment: TNEnvironmentProtocol) {
        current = environment.configure()
    }

    public static var verbose = false

    // MARK: - Initializers
    public init(scheme: TNURLScheme,
                host: String,
                suffix: TNPath?,
                port: Int?,
                configuration: TNRequestConfiguration? = nil) {
        self.scheme = scheme
        self.host = host
        self.suffix = suffix
        self.port = port
        self.configuration = configuration
    }

    public convenience init(scheme: TNURLScheme,
                            host: String) {
        self.init(scheme: scheme,
                  host: host,
                  suffix: nil,
                  port: nil,
                  configuration: nil)
    }

    public convenience init(scheme: TNURLScheme,
                            host: String,
                            configuration: TNRequestConfiguration) {
        self.init(scheme: scheme,
                  host: host,
                  suffix: nil,
                  port: nil,
                  configuration: configuration)
    }

    public convenience init(scheme: TNURLScheme,
                            host: String,
                            port: Int) {
        self.init(scheme: scheme,
                  host: host,
                  suffix: nil,
                  port: port,
                  configuration: nil)
    }

    public convenience init(scheme: TNURLScheme,
                            host: String,
                            port: Int,
                            configuration: TNRequestConfiguration = TNRequestConfiguration()) {
        self.init(scheme: scheme,
                  host: host,
                  suffix: nil,
                  port: port,
                  configuration: configuration)
    }

    public convenience init(scheme: TNURLScheme, host: String, suffix: TNPath) {
        self.init(scheme: scheme,
                  host: host,
                  suffix: suffix,
                  port: nil,
                  configuration: nil)
    }
    public convenience init(scheme: TNURLScheme,
                            host: String, suffix: TNPath,
                            configuration: TNRequestConfiguration = TNRequestConfiguration()) {
        self.init(scheme: scheme,
                  host: host,
                  suffix: suffix,
                  port: nil,
                  configuration: configuration)
    }
}

// MARK: - CustomStringConvertible
extension TNEnvironment: CustomStringConvertible {
    public var description: String {
        var urlComponents = [String]()
        urlComponents.append(scheme.rawValue + ":/")
        urlComponents.append(port != nil ? host + ":" + String(describing: port!) : host)
        if let suffix = suffix {
            urlComponents.append(suffix.convertedPath())
        }

        return urlComponents.joined(separator: "/")
    }
}
