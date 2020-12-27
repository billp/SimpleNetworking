// Request+Interceptors.swift
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

typealias InterceptorFinishedCallbackType = (Data?, TNError?) -> Void

extension Request {
    /// Handles the interceptors if they are passed in configuration object.
    /// - parameters:
    ///     - data: The response data.
    ///     - error: The TNError in case of failure.
    ///     - finishCallback: A callback that continues the execution after the Interceptors handling.
    func processNextInterceptorIfNeeded(data: Data?,
                                        error: TNError?,
                                        finishCallback: @escaping InterceptorFinishedCallbackType) {
        if let nextInterceptor = interceptors?.first {
            nextInterceptor.requestFinished(responseData: data,
                                            error: error,
                                            request: self) { action in
                switch action {
                case .continue:
                    interceptorContinueAction(data: data,
                                              error: error,
                                              finishCallback: finishCallback)
                case .retry(let delay):
                    interceptorRetryAction(withDelay: delay ?? 0,
                                           finishCallback: finishCallback)
                }
            }
        } else {
            finishCallback(data, error)
        }
    }

    /// Initializes the interceptors chain.
    func initializeInterceptorsChainIfNeeded() {
        guard let interceptors = configuration.interceptors,
              self.interceptors == nil,
              !configuration.skipInterceptors else {
            return
        }
        self.interceptors = interceptors.map { $0.init() }
    }

    // MARK: Helpers

    /// Continue action of Interceptors.
    /// - parameters:
    ///     - data: The response data.
    ///     - error: The TNError in case of failure.
    ///     - finishCallback: A callback that continues the execution after the Interceptors handling.
    func interceptorContinueAction(data: Data?,
                                   error: TNError?,
                                   finishCallback: @escaping InterceptorFinishedCallbackType) {
        // Remove the interceptor from chain.
        interceptors?.removeFirst()

        // If the request is retried and succeeded
        if let data = data, error == nil, retryCount > 0 {
            // ...and the interceptor is the last in chain.
            if interceptors?.isEmpty == true {
                // Call the success completion handler directly.
                successCompletionHandler?(data, urlResponse)
            } else {
                // Else move to the next interceptor.
                processNextInterceptorIfNeeded(data: data,
                                               error: nil,
                                               finishCallback: finishCallback)
            }
        } else {
            //  If the interceptor is the last in chain
            if interceptors?.isEmpty == true {
                // Continue with the normal execution.
                finishCallback(data, error)
            } else {
                // Else move to the next interceptor.
                processNextInterceptorIfNeeded(data: data,
                                               error: nil,
                                               finishCallback: finishCallback)
            }

        }
    }

    /// Retry entry-point of Interceptors.
    /// - parameters:
    ///     - delay: The delay between retries.
    ///     - finishCallback: A callback that continues the execution after the Interceptors handling.
    func interceptorRetryAction(withDelay delay: TimeInterval,
                                finishCallback: @escaping InterceptorFinishedCallbackType) {
        guard let newRequest = self.copy() as? Request else {
            return
        }
        retryCount += 1

        // Skip interceptors for new request to prevent infinite loops.
        newRequest.configuration.skipInterceptors = true

        // Prevent duplicate print log on completed.
        self.skipLogOnComplete = true

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Reset the request start time.
            self.startedAt = Date()

            // Retry request for different types.
            switch self.requestType {
            case .data:
                self.retryDataRequest(request: newRequest,
                                      finishCallback: finishCallback)
            case .upload:
                self.retryUploadRequest(request: newRequest,
                                        finishCallback: finishCallback)
            case .download(let file):
                self.retryDownloadRequest(request: newRequest,
                                          filePath: file,
                                          finishCallback: finishCallback)
            }
        }
    }

    /// Retry request of .data type.
    /// - parameters:
    ///     - request: The new copied request.
    ///     - finishCallback: A callback that continues the execution after the Interceptors handling.
    func retryDataRequest(request: Request,
                          finishCallback: @escaping InterceptorFinishedCallbackType) {
        request.start(responseType: Data.self, onSuccess: { data in
            self.processNextInterceptorIfNeeded(data: data,
                                                error: nil,
                                                finishCallback: finishCallback)
        }, onFailure: { error, data in
            self.processNextInterceptorIfNeeded(data: data,
                                                error: error,
                                                finishCallback: finishCallback)
        })
    }

    /// Retry request of .upload type.
    /// - parameters:
    ///     - request: The new copied request.
    ///     - finishCallback: A callback that continues the execution after the Interceptors handling.
    func retryUploadRequest(request: Request,
                            finishCallback: @escaping InterceptorFinishedCallbackType) {
        request.startUpload(
            responseType: Data.self,
            progressUpdate: self.progressCallback,
            onSuccess: { data in
                self.processNextInterceptorIfNeeded(data: data,
                                                    error: nil,
                                                    finishCallback: finishCallback)

            }, onFailure: { error, data in
                self.processNextInterceptorIfNeeded(data: data,
                                                    error: error,
                                                    finishCallback: finishCallback)
            })
    }

    /// Retry request of .download type.
    /// - parameters:
    ///     - request: The new copied request.
    ///     - finishCallback: A callback that continues the execution after the Interceptors handling.
    func retryDownloadRequest(request: Request,
                              filePath: String,
                              finishCallback: @escaping InterceptorFinishedCallbackType) {
        request.startDownload(
            filePath: filePath,
            progressUpdate: self.progressCallback,
            onSuccess: {
                self.processNextInterceptorIfNeeded(data: Data(),
                    error: nil,
                    finishCallback: finishCallback)
            }, onFailure: { error, data in
                self.processNextInterceptorIfNeeded(data: data,
                                                    error: error,
                                                    finishCallback: finishCallback)
            })
    }
}
