//
//  TNRouter.swift
//  Pods-TermiNetwork_Example
//
//  Created by Vasilis Panagiotopoulos on 03/10/2018.
//
import Foundation
import UIKit
    
open class TNRouter<Route: TNRouterProtocol> {
    /// Add a default constructor just to be able to create instances.
    public init() { }
    
    /**
     Starts a requess. The response object in success callback is of type Decodable.
     
     - parameters:
     - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
     - skipBeforeAfterAllRequestsHooks: A boolean that indicates if the request takes part to beforeAllRequests/afterAllRequests. Default value is true (optional)
     - route: a TNRouteProtocol enum value
     - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
     - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start<T>(queue: TNQueue? = TNQueue.shared, _ route: Route, responseType: T.Type, onSuccess: @escaping TNSuccessCallback<T>, onFailure: @escaping TNFailureCallback) where T: Decodable {
        let call = TNRequest(route: route)
        
        call.start(queue: queue, responseType: responseType, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Starts a  requess. The response object in success callback is of type UIImage.
     
     - parameters:
     - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
     - skipBeforeAfterAllRequestsHooks: A boolean that indicates if the request takes part to beforeAllRequests/afterAllRequests. Default value is true (optional)
     - route: a TNRouteProtocol enum value
     - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
     - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start<T: UIImage>(queue: TNQueue? = TNQueue.shared, _ route: Route, responseType: T.Type, onSuccess: @escaping TNSuccessCallback<T>, onFailure: @escaping TNFailureCallback) {
        let call = TNRequest(route: route)
        call.start(queue: queue, responseType: responseType, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    /**
     Starts a requess. The response object in success callback is of type Data.
     
     - parameters:
     - queue: A TNQueue instance. If no queue is specified it uses the default one. (optional)
     - skipBeforeAfterAllRequestsHooks: A boolean that indicates if the request takes part to beforeAllRequests/afterAllRequests. Default value is true (optional)
     - route: a TNRouteProtocol enum value
     - onSuccess: specifies a success callback of type TNSuccessCallback<T> (optional)
     - onFailure: specifies a failure callback of type TNFailureCallback<T> (optional)
     */
    public func start(queue: TNQueue? = TNQueue.shared, _ route: Route, onSuccess: @escaping TNSuccessCallback<Data>, onFailure: @escaping TNFailureCallback) {
        let call = TNRequest(route: route)
        call.start(queue: queue, responseType: Data.self, onSuccess: onSuccess, onFailure: onFailure)
    }
}
