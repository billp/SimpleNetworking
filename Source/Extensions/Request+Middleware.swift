// Request+Middleware.swift
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

extension Request {
    func shouldHandleMiddlewares() -> Bool {
        guard let middlewares = configuration.requestMiddlewares else {
            return false
        }
        return middlewares.count > 0
    }

    func handleMiddlewareBodyBeforeSendIfNeeded(params: [String: Any?]?) throws -> [String: Any?]? {
        guard shouldHandleMiddlewares() else {
            return params
        }

        var newParams = params
        try configuration.requestMiddlewares?.forEach { middleware in
            newParams = try middleware.init().processBodyBeforeSend(with: newParams)
        }
        return newParams
    }

    func handleMiddlewareBodyAfterReceiveIfNeeded(responseData: Data?) throws -> Data? {
        guard shouldHandleMiddlewares() else {
            return responseData
        }

        var newResponseData = responseData
        try configuration.requestMiddlewares?.forEach { middleware in
            newResponseData = try middleware.init().processBodyAfterReceive(with: newResponseData)
        }
        return newResponseData
    }

    func handleMiddlewareHeadersBeforeSendIfNeeded(headers: [String: String]?) throws -> [String: String]? {
        guard shouldHandleMiddlewares() else {
            return headers
        }

        var newHeaders = headers
        try configuration.requestMiddlewares?.forEach { middleware in
            newHeaders = try middleware.init().processHeadersBeforeSend(with: newHeaders)
        }
        return newHeaders
    }

    func handleMiddlewareHeadersAfterReceiveIfNeeded(headers: [String: String]?) throws -> [String: String]? {
        guard shouldHandleMiddlewares() else {
            return headers
        }

        var newHeaders = headers
        try configuration.requestMiddlewares?.forEach { middleware in
            newHeaders = try middleware.init().processHeadersAfterReceive(with: newHeaders)
        }
        return newHeaders
    }

}
