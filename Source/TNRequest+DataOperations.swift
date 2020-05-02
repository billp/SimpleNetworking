// TNRequest+DataOperations.swift
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

import UIKit

extension TNRequest {
    /// Adds a request to a queue and starts its execution for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    public func start<T: Decodable>(queue: TNQueue? = TNQueue.shared,
                                    responseType: T.Type,
                                    onSuccess: TNSuccessCallback<T>?,
                                    onFailure: TNFailureCallback?) {
        currentQueue = queue ?? TNQueue.shared
        currentQueue.beforeOperationStart(request: self)

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
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

    /// Adds a request to a queue and starts its execution for UIImage responses.
    ///
    /// - parameters:
    ///     - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///     - responseType: The response type is UIImage.self.
    ///     - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///     - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    public func start<T: UIImage>(queue: TNQueue? = TNQueue.shared,
                                  responseType: T.Type,
                                  onSuccess: TNSuccessCallback<T>?,
                                  onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            let image = T(data: data)

            if image == nil {
                let tnError = TNError.responseInvalidImageData
                TNLog.logRequest(request: self,
                                 data: data,
                                 urlResponse: urlResponse,
                                 tnError: tnError)

                onFailure?(.responseInvalidImageData, data)
                self.handleDataTaskFailure(with: data,
                                           urlResponse: nil,
                                           tnError: tnError)
            } else {
                TNLog.logRequest(request: self,
                                 data: data,
                                 urlResponse: urlResponse,
                                 tnError: nil)
                onSuccess?(image ?? T())
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: nil,
                                             tnError: nil)
            }
        }, onFailure: { tnError, data in
            onFailure?(tnError, data)
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError)
        })

        currentQueue.addOperation(self)
    }

    /// Adds a request to a queue and starts its execution for String responses.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - responseType: The response type is String.self.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>
    public func start(queue: TNQueue? = TNQueue.shared,
                      responseType: String.Type,
                      onSuccess: TNSuccessCallback<String>?,
                      onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            DispatchQueue.main.async {
                if let string = String(data: data, encoding: .utf8) {
                    TNLog.logRequest(request: self,
                                     data: data,
                                     urlResponse: urlResponse,
                                     tnError: nil)

                    onSuccess?(string)
                    self.handleDataTaskCompleted(with: data,
                                                 urlResponse: urlResponse,
                                                 tnError: nil)
                } else {
                    let tnError = TNError.cannotConvertToString
                    TNLog.logRequest(request: self,
                                     data: data,
                                     urlResponse: urlResponse,
                                     tnError: tnError)
                    onFailure?(tnError, data)
                    self.handleDataTaskFailure(with: data,
                                               urlResponse: nil,
                                               tnError: tnError)
                }

            }
        }, onFailure: { tnError, data in
            onFailure?(tnError, data)
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError)
        })

        currentQueue.addOperation(self)
    }

    /// Adds a request to a queue and starts its execution for Data responses.
    ///
    /// - parameters:
    ///     - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///     - responseType: The response type is Data.self.
    ///     - onSuccess: specifies a success callback of type TNSuccessCallback<T>
    ///     - onFailure: specifies a failure callback of type TNFailureCallback<T>
    public func start(queue: TNQueue? = TNQueue.shared,
                      responseType: Data.Type,
                      onSuccess: TNSuccessCallback<Data>?,
                      onFailure: TNFailureCallback?) {
        currentQueue = queue
        currentQueue.beforeOperationStart(request: self)

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            DispatchQueue.main.async {
                TNLog.logRequest(request: self,
                                 data: data,
                                 urlResponse: urlResponse,
                                 tnError: nil)
                onSuccess?(data)
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             tnError: nil)
            }
        }, onFailure: { tnError, data in
            onFailure?(tnError, data)
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError)
        })

        currentQueue.addOperation(self)
    }
}
