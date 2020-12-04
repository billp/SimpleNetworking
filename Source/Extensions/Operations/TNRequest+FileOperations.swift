// TNRequest+FileOperations.swift
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

/// Progress callback type
/// - parameters:
///     - bytesSent/bytesDownloaded: The total size of bytes sent/downloaded to/from server.
///     - totalBytes: The total size of upload/download data.
///     - progress: Download/Upload progress
public typealias TNProgressCallbackType = (Int, Int, Float) -> Void

extension TNRequest {
    /// Adds a request to a queue and starts its execution for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    /// - returns: The TNRequest object.
    @discardableResult
    public func startUpload<T: Decodable>(queue: TNQueue? = TNQueue.shared,
                                          responseType: T.Type,
                                          progressUpdate: TNProgressCallbackType?,
                                          onSuccess: TNSuccessCallback<T>?,
                                          onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue ?? TNQueue.shared

        dataTask = TNSessionTaskFactory.makeUploadTask(with: self,
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

    /// Adds a request to a queue and starts its execution for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - transformer: The transformer object that handles the transformation.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    /// - returns: The TNRequest object.
    @discardableResult
    public func startUpload<FromType: Decodable, ToType>(queue: TNQueue? = TNQueue.shared,
                                                         transformer: TNTransformer<FromType, ToType>,
                                                         progressUpdate: TNProgressCallbackType?,
                                                         onSuccess: TNSuccessCallback<ToType>?,
                                                         onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue ?? TNQueue.shared

        dataTask = TNSessionTaskFactory.makeUploadTask(with: self,
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
                onSuccess?(try object.transform(with: transformer))
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

    /// Adds a request to a queue and starts its execution for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - filePath: The destination file path to save the file.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    /// - returns: The TNRequest object.
    @discardableResult
    public func startDownload(queue: TNQueue? = TNQueue.shared,
                              filePath: String,
                              progressUpdate: TNProgressCallbackType?,
                              onSuccess: TNDownloadSuccessCallback?,
                              onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue ?? TNQueue.shared

        dataTask = TNSessionTaskFactory.makeDownloadTask(with: self,
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
