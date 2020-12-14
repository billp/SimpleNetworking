// TNRequestHelpers.swift
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

typealias TNRequestProcessReturnType = (data: Data?, tnError: TNError?)

/// TNRequest helpers.
class TNRequestHelpers {
    /// Generates errors from generated by session task completion handler
    /// - Parameters:
    ///     - serverError: the error object from the completion handler
    /// - Returns:
    ///     - data: Data on success after middleware handler
    ///     - tnError: TNError on any generated error
    static func processData(with tnRequest: TNRequest,
                            data: Data? = nil,
                            urlResponse: URLResponse?,
                            serverError: Error?) -> TNRequestProcessReturnType {
        var customError: TNError?
        var data = data

        /// Error handling
        if let error = serverError {
            if (error as NSError).code == NSURLErrorCancelled {
                customError = TNError.cancelled(error)
            } else {
                customError = TNError.networkError(error)
            }
        } else if let response = urlResponse as? HTTPURLResponse {
            let statusCode = response.statusCode
            if response.statusCode / 100 != 2 {
                customError = TNError.notSuccess(statusCode)
            }
        }

        do {
            data = try tnRequest.handleMiddlewareBodyAfterReceiveIfNeeded(responseData: data)
        } catch {
            if let error = error as? TNError {
                customError = error
            }
        }

        return TNRequestProcessReturnType(data: data, tnError: customError)
    }
}