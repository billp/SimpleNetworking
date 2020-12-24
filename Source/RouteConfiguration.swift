// RouteConfiguration.swift
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

/// Route configuration class which is used in Route protocol implementations.
public final class RouteConfiguration {
    /// A Method to use, for example .get, .post, etc.
    var method: Method
    /// A path of the request (will be appended to the base URL, for example .path(["user", "13"]).
    var path: Path
    /// The parameters of the request.
    var params: [String: Any?]?
    /// The headers of the request. They will override (if needed) those from configuration objects.
    var headers: [String: String]?
    /// A configuration object (Optional, e.g. if you want ot use custom configuration for a specific route).
    var configuration: Configuration?
    /// A path of the file in the mock data bundle specified in configuration object.
    /// This will be used only if useMockData is set to true in the configuration object.
    var mockFilePath: Path?

    /// Route configuration initializer
    /// 
    /// - parameters:
    ///   - method: A Method to use, for example .get, .post, etc.
    ///   - path: A path of the request (will be appended to the base URL, for example .path(["user", "13"]).
    ///   - params: The parameters of the request.
    ///   - headers: A configuration object (Optional, e.g. if you want ot use custom
    ///   configuration for a specific route).
    ///   - configuration: The configuration object of the request.
    ///   - mockFilePath: A path of the file in the mock data bundle specified in configuration object.
    ///         This will be used only if useMockData is set to true in the configuration object.
    public init(method: Method,
                path: Path,
                params: [String: Any?]? = nil,
                headers: [String: String]? = nil,
                configuration: Configuration? = nil,
                mockFilePath: Path? = nil) {
        self.method = method
        self.path = path
        self.params = params
        self.headers = headers
        self.configuration = configuration
        self.mockFilePath = mockFilePath
    }
}
