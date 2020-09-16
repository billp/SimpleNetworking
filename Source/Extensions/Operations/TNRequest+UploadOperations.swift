// TNRequest+UploadOperations.swift
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
///     - bytesSent: The total size of bytes sent to server.
///     - totalBytes: The total size of upload data.
///     - progress: Upload progress
public typealias TNProgressCallbackType = (Int, Int, Float) -> Void

extension TNRequest {
    /// Adds a request to a queue and starts its execution for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - data: The data to upload
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - progress: specifies a progress callback to get upload progress updates.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    public func startUpload<T: Decodable>(queue: TNQueue? = TNQueue.shared,
                                          responseType: T.Type,
                                          progressUpdate: TNProgressCallbackType?,
                                          onSuccess: TNSuccessCallback<T>?,
                                          onFailure: TNFailureCallback?) {
        currentQueue = queue ?? TNQueue.shared
        currentQueue.beforeOperationStart(request: self)

        dataTask = TNSessionTaskFactory.makeUploadTask(with: self,
                                                       progressUpdate: progressUpdate,
                                                       completionHandler: { data, urlResponse in
            let object: T!

            do {
               object = try data.deserializeJSONData() as T
            } catch let error {
               let tnError = TNError.cannotDeserialize(error)
               TNLog.logRequest(request: self,
                                data: data,
                                urlResponse: nil,
                                tnError: tnError)
               onFailure?(tnError, data)
               self.handleDataTaskFailure(with: data,
                                          urlResponse: urlResponse,
                                          tnError: tnError)
               return
            }

            TNLog.logRequest(request: self,
                             data: data,
                             urlResponse: urlResponse,
                             tnError: nil)
            onSuccess?(object)
            self.handleDataTaskCompleted(with: data,
                                        urlResponse: urlResponse,
                                        tnError: nil)
        }, onFailure: { tnError, data in
            onFailure?(tnError, data)
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError)
        })

        currentQueue.addOperation(self)
    }
}
