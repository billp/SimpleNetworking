// Request+FileOperations.swift
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

/// Progress callback type
/// - parameters:
///     - bytesSent/bytesDownloaded: The total size of bytes sent/downloaded to/from server.
///     - totalBytes: The total size of upload/download data.
///     - progress: Download/Upload progress
public typealias ProgressCallbackType = (Int, Int, Float) -> Void

extension Request {
    /// Adds a request to a queue and starts an upload process for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A Queue instance. If no queue is specified it uses the default one.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type SuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type FailureCallback<T>.
    /// - returns: The Request object.
    @discardableResult
    public func startUpload<T: Decodable>(queue: Queue? = Queue.shared,
                                          responseType: T.Type,
                                          progressUpdate: ProgressCallbackType?,
                                          onSuccess: SuccessCallback<T>?,
                                          onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue ?? Queue.shared

        dataTask = SessionTaskFactory.makeUploadTask(with: self,
                                                       progressUpdate: progressUpdate,
                                                       completionHandler: { data, urlResponse in
            let object: T!

            do {
                object = try data.deserializeJSONData(withKeyDecodingStrategy:
                                                        self.configuration.keyDecodingStrategy) as T
            } catch let error {
                let tnError = TNError.cannotDeserialize(String(describing: T.self), error)
               self.handleDataTaskFailure(with: data,
                                          urlResponse: urlResponse,
                                          tnError: tnError,
                                          onFailure: onFailure)
               return
            }

            onSuccess?(object)
            self.handleDataTaskCompleted(with: data,
                                        urlResponse: urlResponse,
                                        tnError: nil)
        }, onFailure: { tnError, data in
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError,
                                       onFailure: onFailure)
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for Transformer types.
    ///
    /// - parameters:
    ///    - queue: A Queue instance. If no queue is specified it uses the default one.
    ///    - transformer: The transformer object that handles the transformation.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type SuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type FailureCallback<T>.
    /// - returns: The Request object.
    @discardableResult
    public func startUpload<FromType: Decodable, ToType>(queue: Queue? = Queue.shared,
                                                         transformer: Transformer<FromType, ToType>.Type,
                                                         progressUpdate: ProgressCallbackType?,
                                                         onSuccess: SuccessCallback<ToType>?,
                                                         onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue ?? Queue.shared

        dataTask = SessionTaskFactory.makeUploadTask(with: self,
                                                       progressUpdate: progressUpdate,
                                                       completionHandler: { data, urlResponse in
            let object: FromType!

            do {
                object = try data.deserializeJSONData(withKeyDecodingStrategy:
                                                        self.configuration.keyDecodingStrategy) as FromType
            } catch let error {
                let tnError = TNError.cannotDeserialize(String(describing: FromType.self), error)
               self.handleDataTaskFailure(with: data,
                                          urlResponse: urlResponse,
                                          tnError: tnError,
                                          onFailure: onFailure)
               return
            }

            // Transformation
            do {
                onSuccess?(try object.transform(with: transformer.init()))
            } catch let error {
                guard let tnError = error as? TNError else {
                    return
                }
                self.handleDataTaskFailure(with: data,
                                           urlResponse: nil,
                                           tnError: tnError,
                                           onFailure: onFailure)
                return
            }

            self.handleDataTaskCompleted(with: data,
                                        urlResponse: urlResponse,
                                        tnError: nil)
        }, onFailure: { tnError, data in
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError,
                                       onFailure: onFailure)
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for String types.
    ///
    /// - parameters:
    ///    - queue: A Queue instance. If no queue is specified it uses the default one.
    ///    - filePath: The destination file path to save the file.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type SuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type FailureCallback<T>.
    /// - returns: The Request object.
    @discardableResult
    public func startDownload(queue: Queue? = Queue.shared,
                              filePath: String,
                              progressUpdate: ProgressCallbackType?,
                              onSuccess: DownloadSuccessCallback?,
                              onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue ?? Queue.shared

        dataTask = SessionTaskFactory.makeDownloadTask(with: self,
                                                         filePath: filePath,
                                                         progressUpdate: progressUpdate,
                                                         completionHandler: { data, urlResponse in
            onSuccess?()
            self.handleDataTaskCompleted(with: data,
                                        urlResponse: urlResponse,
                                        tnError: nil)
        }, onFailure: { tnError, data in
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError,
                                       onFailure: onFailure)
        })

        currentQueue.addOperation(self)
        return self
    }
}