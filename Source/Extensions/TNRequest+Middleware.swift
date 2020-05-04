//
//  TNRequest+Middleware.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 20/4/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import UIKit

extension TNRequest {
    func shouldHandleMiddlewares() -> Bool {
        guard let middlewares = configuration.requestMiddlewares else {
            return false
        }
        return middlewares.count > 0
    }

    func handleMiddlewareBodyBeforeSendIfNeeded(params: [String: Any?]?) throws -> [String: Any?]? {
        var newParams = params
        try configuration.requestMiddlewares?.forEach { middleware in
            newParams = try middleware.modifyBodyBeforeSend(with: newParams)
        }
        return newParams
    }

    func handleMiddlewareBodyAfterReceiveIfNeeded(responseData: Data?) throws -> Data? {
        var newResponseData = responseData
        try configuration.requestMiddlewares?.forEach { middleware in
            newResponseData = try middleware.modifyBodyAfterReceive(with: newResponseData)
        }
        return newResponseData
    }

    func handleMiddlewareHeadersBeforeSendIfNeeded(headers: [String: String]?) throws -> [String: String]? {
        var newHeaders = headers
        try configuration.requestMiddlewares?.forEach { middleware in
            newHeaders = try middleware.modifyHeadersBeforeSend(with: newHeaders)
        }
        return newHeaders
    }
}
