// SessionTaskFactory.swift
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

/// Factory class that creates Session task for each specific case
internal class SessionTaskFactory {
    /// Creates a data task request.
    /// - Parameters:
    ///     - Request: A Request instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeDataTask(with request: Request,
                             completionHandler: ((Data, URLResponse?) -> Void)?,
                             onFailure: FailureCallback?) -> URLSessionDataTask? {

        let urlRequest: URLRequest!
        do {
            urlRequest = try request.asRequest()
        } catch let error {
            guard let tnError = error as? TNError else {
                return nil
            }

            request.handleDataTaskFailure(with: nil,
                                          urlResponse: nil,
                                          tnError: tnError,
                                          onFailure: onFailure)
            return nil
        }

        /// Create mock request if needed
        if request.shouldMockRequest() {
            return request.createMockRequest(request: urlRequest,
                                             completionHandler: completionHandler,
                                             onFailure: onFailure)
        }

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: Session<Data>(with: request),
                                 delegateQueue: OperationQueue.current)

        let dataTask = session.dataTask(with: urlRequest) { data, urlResponse, error in
            let dataResult = RequestHelpers.processData(with: request,
                                                        data: data,
                                                        urlResponse: urlResponse,
                                                        serverError: error)

            if let tnError = dataResult.tnError {
                onFailure?(tnError, data)
            } else {
                completionHandler?(dataResult.data ?? Data(), urlResponse)
            }
        }

        return dataTask
    }

    /// Creates an upload task request.
    /// - Parameters:
    ///     - Request: A Request instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeUploadTask(with request: Request,
                               progressUpdate: ProgressCallbackType?,
                               completionHandler: ((Data, URLResponse?) -> Void)?,
                               onFailure: FailureCallback?) -> URLSessionUploadTask? {

        guard let params = request.params as? [String: MultipartFormDataPartType] else {
            onFailure?(.invalidMultipartParams, nil)
            return nil
        }

        // Set the type of the request
        request.requestType = .upload

        var urlRequest: URLRequest

        let boundary = MultipartFormDataHelpers.generateBoundary()
        request.configuration.requestBodyType = .multipartFormData(boundary: boundary)
        request.multipartBoundary = boundary
        do {
            request.multipartFormDataStream = try MultipartFormDataStream(request: request,
                                                                          params: params,
                                                                          boundary: boundary,
                                                                          uploadProgressCallback: progressUpdate)
            urlRequest = try request.asRequest()
        } catch let error {
            guard let tnError = error as? TNError else {
                return nil
            }
            onFailure?(tnError, nil)
            return nil
        }

        let sessionDelegate = Session<Data>(with: request,
                                            progressCallback: progressUpdate,
                                            completedCallback: { (data, urlResponse, error) in
            let dataResult = RequestHelpers.processData(with: request,
                                                          data: data,
                                                          urlResponse: urlResponse,
                                                          serverError: error)

            if let tnError = dataResult.tnError {
                request.handleDataTaskFailure(with: dataResult.data,
                                              urlResponse: nil,
                                              tnError: tnError,
                                              onFailure: onFailure)
            } else {
                completionHandler?(dataResult.data ?? Data(), urlResponse)
            }
        }, failureCallback: onFailure)

        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: sessionDelegate,
                                 delegateQueue: OperationQueue.current)
        let uploadTask = session.uploadTask(withStreamedRequest: urlRequest)

        return uploadTask
    }

    /// Creates a download task request.
    /// - Parameters:
    ///     - Request: A Request instance
    ///     - completionHandler: A completion handler for success
    ///     - onFailure: A completion handler for failures
    static func makeDownloadTask(with request: Request,
                                 filePath destinationPath: String,
                                 progressUpdate: ProgressCallbackType?,
                                 completionHandler: ((Data?, URLResponse?) -> Void)?,
                                 onFailure: FailureCallback?) -> URLSessionDownloadTask? {
        let urlRequest: URLRequest!
        do {
            urlRequest = try request.asRequest()
        } catch let error {
            guard let tnError = error as? TNError else {
                return nil
            }

            request.handleDataTaskFailure(with: nil,
                                            urlResponse: nil,
                                            tnError: tnError,
                                            onFailure: onFailure)
            return nil
        }

        // Set the type of the request
        request.requestType = .download(destinationPath)

        let callback: ((URL?, URLResponse?, Error?) -> Void)? = { url, urlResponse, error in
            let dataResult = RequestHelpers.processData(with: request,
                                                        urlResponse: urlResponse,
                                                        serverError: error)

            if let tnError = dataResult.tnError {
                onFailure?(tnError, nil)
            } else {
                if let path = url?.path {
                    do {
                        try FileManager.default.moveItem(atPath: path, toPath: destinationPath)
                        completionHandler?(dataResult.data, urlResponse)
                    } catch let error {
                        let tnError = TNError.downloadedFileCannotBeSaved(error)
                        onFailure?(tnError, nil)
                        return
                    }
                }
            }
        }
        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: Session<URL>(with: request,
                                                        progressCallback: progressUpdate,
                                                        completedCallback: callback,
                                                        failureCallback: onFailure),
                                 delegateQueue: OperationQueue.current)

        let task = session.downloadTask(with: urlRequest)
        task.resume()

        return task
    }
}
