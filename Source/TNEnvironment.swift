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

/// This protocol should be inhereted by the Environment enum.
public protocol TNEnvironmentProtocol {
    /// Thus is required in order to construct the url of the request.
    func configure() -> TNEnvironment
}

/// The url scheme that will be used in an environment
public enum TNURLScheme: String {
    /// HTTP Schema
    case http
    /// HTTPS Schema
    case https
}

/// The TNEnvironment contains information about host, port, configuration and it's used in TNRequest instances.
open class TNEnvironment {
    // MARK: Properties
    var scheme: TNURLScheme
    var host: String
    var port: Int?
    var suffix: TNPath?
    var configuration: TNConfiguration?

    // MARK: Static members
    public static var current: TNEnvironment!

    /// Set a global environment for all TNRequest instances.
    public static func set(_ environment: TNEnvironmentProtocol) {
        current = environment.configure()
    }

    // MARK: Initializers

    /// Instantiates an environment
    ///
    /// - parameters:
    ///     - scheme: The scheme of the host (.http or .https)
    ///     - host: The actual host, e.g. s1.example.com
    ///     - suffix: The path after the host name, e.g. .path["api","v1"]
    ///     - port: The port the environment is using, e.g. 8080
    ///     - configuration: A configuration instance that will be inherited by each request and route
    public init(scheme: TNURLScheme,
                host: String,
                suffix: TNPath? = nil,
                port: Int? = nil,
                configuration: TNConfiguration? = nil) {
        self.scheme = scheme
        self.host = host
        self.suffix = suffix
        self.port = port
        self.configuration = configuration
    }
}

// MARK: CustomStringConvertible
extension TNEnvironment: CustomStringConvertible {
    public var description: String {
        var urlComponents = [String]()
        urlComponents.append(scheme.rawValue + ":/")
        urlComponents.append(port != nil ? host + ":" + String(describing: port!) : host)
        if let suffix = suffix {
            urlComponents.append(suffix.convertedPath)
        }

        return urlComponents.joined(separator: "/")
    }
}
