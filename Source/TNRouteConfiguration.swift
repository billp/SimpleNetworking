// TNRouteConfiguration.swift
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

import UIKit

/// Used to configure a route
public class TNRouteConfiguration {
    var method: TNMethod
    var path: TNPath
    var params: [String: Any?]?
    var headers: [String: String]?
    var configuration: TNConfiguration?
    var mockFilePath: TNPath?

    /// Route configuration initializer
    /// 
    /// - parameters:
    ///   - method: A TNMethod to use, for example .get, .post, etc.
    ///   - path: A path that will be appended to the base url speficified in the environment,
    ///         for example .path(["user", "13"])
    ///   - params: The params that will be send to server based on the request body type
    ///   - headers: The headers that will be send to server, this will be merged with the existed headers if specified
    ///         in condiguration object
    ///   - configuration: The configuration object of the request.
    ///   - mockFilePath: A path of the response in the mock data bundle specified in configuration object.
    ///         This will be used only if useMockData is set to true in the configuration object
    public init(method: TNMethod,
                path: TNPath,
                params: [String: Any?]? = nil,
                headers: [String: String]? = nil,
                configuration: TNConfiguration? = nil,
                mockFilePath: TNPath? = nil) {
        self.method = method
        self.path = path
        self.params = params
        self.headers = headers
        self.configuration = configuration
        self.mockFilePath = mockFilePath
    }
}
