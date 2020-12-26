//
//  Request+NSCopying.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 25/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation

extension Request: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let request = Request()
        request.method = method
        request.currentQueue = currentQueue
        request.params = params
        request.path = path
        request.pathType = pathType
        request.mockFilePath = mockFilePath
        request.multipartBoundary = multipartBoundary
        request.multipartFormDataStream = multipartFormDataStream
        request.requestType = requestType
        request.headers = headers
        request.environment = environment
        request.configuration = configuration

        return request
    }
}
