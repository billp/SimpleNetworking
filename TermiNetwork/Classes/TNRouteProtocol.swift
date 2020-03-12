//
//  TNRouter.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 06/03/2018.
//

import Foundation

// MARK: - Custom types
public struct TNRouteConfiguration {
    var method: TNMethod
    var path: TNPath
    var params: [String: Any?]? = nil
    var headers: [String: String]? = nil
    var requestConfiguration: TNRequestConfiguration? = nil
    
    public init(method: TNMethod, path: TNPath, params: [String: Any?]? = nil, headers: [String: String]? = nil, requestConfiguration: TNRequestConfiguration? = TNRequestConfiguration.default) {
        self.method = method
        self.path = path
        self.params = params
        self.headers = headers
        self.requestConfiguration = requestConfiguration
    }
}

// MARK: - Protocols
public protocol TNRouterProtocol {
    func configure() -> TNRouteConfiguration
}
