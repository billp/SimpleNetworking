// TNRouter.swift
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
import UIKit

open class TNRouter<Route: TNRouterProtocol> {
    // MARK: Properties
    fileprivate var environment: TNEnvironment?

    ///
    /// Init with environment that overrides the one set by TNEnvironment.set(_).
    ///
    public init(environment: TNEnvironmentProtocol? = nil) {
        self.environment = environment?.configure() ?? TNEnvironment.current
    }

    ///
    /// Starts a requess. The response object in success callback is of type Decodable.
    ///
    ///    - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///    - skipBeforeAfterAllRequestsHooks: A boolean that indicates if the request takes
    ///    part to beforeAllRequests/afterAllRequests. Default value is true (optional)
    ///    - route: a TNRouteProtocol enum value
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)

    public func start<T>(queue: TNQueue? = TNQueue.shared,
                         _ route: Route,
                         responseType: T.Type,
                         onSuccess: @escaping TNSuccessCallback<T>,
                         onFailure: TNFailureCallback?) where T: Decodable {
        let call = TNRequest(route: route,
                             environment: environment)

        call.start(queue: queue,
                   responseType: responseType,
                   onSuccess: onSuccess,
                   onFailure: onFailure)
    }

    ///
    /// Starts a  requess. The response object in success callback is of type UIImage.

    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///    - skipBeforeAfterAllRequestsHooks: A boolean that indicates if the request takes part to
    ///    beforeAllRequests/afterAllRequests. Default value is true (optional)
    ///    - route: a TNRouteProtocol enum value
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)

    public func start<T: UIImage>(queue: TNQueue? = TNQueue.shared,
                                  _ route: Route,
                                  responseType: T.Type,
                                  onSuccess: @escaping TNSuccessCallback<T>,
                                  onFailure: @escaping TNFailureCallback) {
        let call = TNRequest(route: route,
                             environment: environment)
        call.start(queue: queue,
                   responseType: responseType,
                   onSuccess: onSuccess,
                   onFailure: onFailure)
    }

    ///
    /// Starts a requess. The response object in success callback is of type Data.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
    ///    - skipBeforeAfterAllRequestsHooks: A boolean that indicates if the request takes part to
    ///       beforeAllRequests/afterAllRequests. Default value is true (optional)
    ///    - route: a TNRouteProtocol enum value
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)

    public func start(queue: TNQueue? = TNQueue.shared,
                      _ route: Route,
                      onSuccess: @escaping TNSuccessCallback<Data>,
                      onFailure: @escaping TNFailureCallback) {
        let call = TNRequest(route: route,
                             environment: environment)
        call.start(queue: queue,
                   responseType: Data.self,
                   onSuccess: onSuccess,
                   onFailure: onFailure)
    }

    /// Returns a TNRequest for later use.
    public func request(forRoute route: Route) -> TNRequest {
        return TNRequest(route: route,
                         environment: environment)
    }
}
