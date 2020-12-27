// Router.swift
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

/// This class is used to create instances of Router that can be used to start requests based on the given Route.
public final class Router<Route: RouteProtocol> {
    // MARK: Properties
    fileprivate var environment: Environment?

    /// Router configuration
    public var configuration: Configuration?

    /// Initialize with environment that overrides the one set by Environment.set(_).
    public init(environment: EnvironmentProtocol? = nil,
                configuration: Configuration? = nil) {
        self.environment = environment?.configure() ?? Environment.current
        self.configuration = configuration
    }

    /// Returns a Request that can be used later, e.g. for starting the request in a later time or canceling it.
    ///
    /// - parameters:
    ///    - route: a RouteProtocol enum value
    public func request(for route: Route) -> Request {
        return Request(route: route,
                       environment: environment,
                       configuration: configuration)
    }
}
