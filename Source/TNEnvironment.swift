// TNEnvironment.swift
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
    private enum EnvironmentType {
        case normal(scheme: TNURLScheme, host: String, port: Int?, suffix: TNPath?)
        case url(String)
    }

    // MARK: Private Properties
    private var type: EnvironmentType

    /// The configuration object.
    public var configuration: TNConfiguration?

    // MARK: Static members
    public static var current: TNEnvironment!

    /// Set a global environment for TermiNetwork.
    /// - parameters:
    ///     - environment: An enum case type that impleements the TNEnvironmentProtocol.
    public static func set(_ environment: TNEnvironmentProtocol) {
        current = environment.configure()
    }

    /// Set a global environment for TermiNetwork with a given String URL.
    /// - parameters:
    ///     - environment: A TNEnvironment object.
    public static func set(_ environment: TNEnvironment) {
        current = environment
    }

    // MARK: Initializers

    /// Initializes an environment.
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
        type = .normal(scheme: scheme, host: host, port: port, suffix: suffix)
        self.configuration = configuration
    }

    /// Initializes an environment with an URL.
    ///
    /// - parameters:
    ///     - url: The scheme of the host (.http or .https)
    public init(url: String,
                configuration: TNConfiguration? = nil) {
        type = .url(url)
        self.configuration = configuration
    }
}

// MARK: Extensions
extension TNEnvironment {
    /// Get the String value of the environment.
    public var stringUrl: String {
        switch type {
        case let .normal(scheme, host, port, suffix):
            var urlComponents = [String]()
            urlComponents.append(scheme.rawValue + ":/")
            urlComponents.append(port != nil ? host + ":" + String(describing: port!) : host)
            if let suffix = suffix {
                urlComponents.append(suffix.convertedPath)
            }

            return urlComponents.joined(separator: "/")
        case let .url(url):
            return url
        }
    }
}
