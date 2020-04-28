// TNSessionTaskFactory.swift
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
//swiftlint:disable function_body_length
import Foundation

/// Factory class that creates Session task for each specific case
class TNSessionTaskFactory {
    /// Creates a data task request.
    /// - Parameters:
    ///     - tnRequest: A TNRequest instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeDataTask(with tnRequest: TNRequest,
                             completionHandler: ((Data) -> Void)?,
                             onFailure: TNFailureCallback?) -> URLSessionDataTask? {

        let request: URLRequest!
        do {
            request = try tnRequest.asRequest()
        } catch let error {
            if let error = error as? TNError {
                onFailure?(error, nil)
            }
            tnRequest.handleDataTaskFailure()
            return nil
        }

        /// Create mock request if needed
        if tnRequest.shouldMockRequest() {
            return tnRequest.createMockRequest(request: request,
                                               completionHandler:
                                completionHandler, onFailure: onFailure)
        }

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: TNSession(withTNRequest: tnRequest),
                                 delegateQueue: OperationQueue.current)

        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            var statusCode: Int?
            tnRequest.data = data
            tnRequest.urlResponse = urlResponse

            /// Error handling
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    tnRequest.customError = TNError.cancelled(error)
                } else {
                    tnRequest.customError = TNError.networkError(error)
                }
            } else if let response = urlResponse as? HTTPURLResponse {
                statusCode = response.statusCode as Int?

                if let statusCode = statusCode, statusCode / 100 != 2 {
                    tnRequest.customError = TNError.notSuccess(statusCode)
                }
            }

            if let customError = tnRequest.customError {
                DispatchQueue.main.async {
                    TNLog.logRequest(request: tnRequest)
                    onFailure?(customError, tnRequest.data)
                    tnRequest.handleDataTaskFailure()
                }
            } else {
                do {
                    tnRequest.data = try tnRequest
                        .handleMiddlewareBodyAfterReceiveIfNeeded(responseData: tnRequest.data)
                    completionHandler?(tnRequest.data ?? Data())
                } catch {
                    if let customError = error as? TNError {
                        tnRequest.customError = customError
                        TNLog.logRequest(request: tnRequest)
                        onFailure?(customError, nil)
                    }
                }
            }
        }

        return dataTask
    }
}
