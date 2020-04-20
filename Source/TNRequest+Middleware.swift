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
        return configuration.requestMiddlewares.count > 0
    }

    func handleMiddlewareBodyBeforeSendIfNeeded(params: [String: Any?]?) -> [String: Any?]? {
        var newParams = params
        configuration.requestMiddlewares.forEach { middleware in
            newParams = middleware.modifyBodyBeforeSend(with: newParams)
        }

        return newParams
    }

    func handleMiddlewareHeadersBeforeSendIfNeeded(headers: [String: String]?) -> [String: String]? {
        var newHeaders = headers
        configuration.requestMiddlewares.forEach { middleware in
            newHeaders = middleware.modifyHeadersBeforeSend(with: newHeaders)
        }
        return newHeaders
    }

}
