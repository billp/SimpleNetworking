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
            guard let tnError = error as? TNError else {
                return nil
            }

            onFailure?(tnError, nil)
            tnRequest.handleDataTaskFailure(withData: nil,
                                            tnError: tnError)
            return nil
        }

        /// Create mock request if needed
        if tnRequest.shouldMockRequest() {
            return tnRequest.createMockRequest(request: request,
                                               completionHandler: completionHandler,
                                               onFailure: onFailure)
        }

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: TNSession(withTNRequest: tnRequest),
                                 delegateQueue: OperationQueue.current)

        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            tnRequest.urlResponse = urlResponse

            let dataResult = TNRequestHelpers.processData(with: tnRequest,
                                                          data: data,
                                                          urlResponse: urlResponse,
                                                          serverError: error)

            if let tnError = dataResult.tnError {
                TNLog.logRequest(request: tnRequest,
                                 data: dataResult.data,
                                 tnError: tnError)
                onFailure?(tnError, dataResult.data)
                tnRequest.handleDataTaskFailure(withData: dataResult.data,
                                                tnError: tnError)
            } else {
                completionHandler?(dataResult.data ?? Data())
            }
        }

        return dataTask
    }

    /// Creates a data task request.
    /// - Parameters:
    ///     - tnRequest: A TNRequest instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeUploadTask(with tnRequest: TNRequest,
                               from: Data,
                               completionHandler: ((Data) -> Void)?,
                               onFailure: TNFailureCallback?) -> URLSessionUploadTask? {

        let request: URLRequest!
        do {
            request = try tnRequest.asRequest()
        } catch let error {
            guard let tnError = error as? TNError else {
                return nil
            }
            onFailure?(tnError, nil)
            tnRequest.handleDataTaskFailure(withData: nil,
                                            tnError: tnError)
            return nil
        }

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: TNSession(withTNRequest: tnRequest),
                                 delegateQueue: OperationQueue.current)
        let uploadTask = session.uploadTask(with: request,
                                            from: from) { (data, response, error) in

        }

        return uploadTask
    }
}
