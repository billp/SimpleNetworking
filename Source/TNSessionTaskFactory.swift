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
// swiftlint:disable function_body_length
import Foundation

/// Factory class that creates Session task for each specific case
class TNSessionTaskFactory {
    /// Creates a data task request.
    /// - Parameters:
    ///     - tnRequest: A TNRequest instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeDataTask(with tnRequest: TNRequest,
                             completionHandler: ((Data, URLResponse?) -> Void)?,
                             onFailure: TNFailureCallback?) -> URLSessionDataTask? {

        let request: URLRequest!
        do {
            request = try tnRequest.asRequest()
        } catch let error {
            guard let tnError = error as? TNError else {
                return nil
            }

            onFailure?(tnError, nil)
            tnRequest.handleDataTaskFailure(with: nil,
                                            urlResponse: nil,
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
                                 delegate: TNSession(with: tnRequest),
                                 delegateQueue: OperationQueue.current)

        let dataTask = session.dataTask(with: request) { data, urlResponse, error in
            let dataResult = TNRequestHelpers.processData(with: tnRequest,
                                                          data: data,
                                                          urlResponse: urlResponse,
                                                          serverError: error)

            if let tnError = dataResult.tnError {
                TNLog.logRequest(request: tnRequest,
                                 data: dataResult.data,
                                 urlResponse: urlResponse,
                                 tnError: tnError)
                onFailure?(tnError, dataResult.data)
                tnRequest.handleDataTaskFailure(with: dataResult.data,
                                                urlResponse: nil,
                                                tnError: tnError)
            } else {
                completionHandler?(dataResult.data ?? Data(), urlResponse)
            }
        }

        return dataTask
    }

    /// Creates an upload task request.
    /// - Parameters:
    ///     - tnRequest: A TNRequest instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeUploadTask(with tnRequest: TNRequest,
                               progressUpdate: TNProgressCallbackType?,
                               completionHandler: ((Data, URLResponse?) -> Void)?,
                               onFailure: TNFailureCallback?) -> URLSessionUploadTask? {

        guard let params = tnRequest.params as? [String: TNMultipartFormDataPartType] else {
            onFailure?(.invalidMultipartParams, nil)
            return nil
        }

        let boundary = TNMultipartFormDataHelpers.generateBoundary()
        tnRequest.configuration.requestBodyType = .multipartFormData(boundary: boundary)
        tnRequest.multipartBoundary = boundary
        tnRequest.multipartFormDataStream = TNMultipartFormDataStream(request: tnRequest,
                                                                      params: params,
                                                                      boundary: boundary,
                                                                      uploadProgressCallback: progressUpdate)

        var request: URLRequest!
        do {
            request = try tnRequest.asRequest()
        } catch let error {
            guard let tnError = error as? TNError else {
                return nil
            }
            onFailure?(tnError, nil)
            tnRequest.handleDataTaskFailure(with: nil,
                                            urlResponse: nil,
                                            tnError: tnError)
            return nil
        }

        let sessionDelegate = TNSession(with: tnRequest,
                                                uploadProgressCallback: progressUpdate,
                                                completedCallback: { (data, urlResponse, error) in
            let dataResult = TNRequestHelpers.processData(with: tnRequest,
                                                          data: data,
                                                          urlResponse: urlResponse,
                                                          serverError: error)

            if let tnError = dataResult.tnError {
                TNLog.logRequest(request: tnRequest,
                                 data: dataResult.data,
                                 urlResponse: urlResponse,
                                 tnError: tnError)
                onFailure?(tnError, dataResult.data)
                tnRequest.handleDataTaskFailure(with: dataResult.data,
                                                urlResponse: nil,
                                                tnError: tnError)
            } else {
                completionHandler?(dataResult.data ?? Data(), urlResponse)
            }
        }, failureCallback: onFailure)

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: sessionDelegate,
                                 delegateQueue: OperationQueue.current)
        let uploadTask = session.uploadTask(withStreamedRequest: request)

        return uploadTask
    }
}
