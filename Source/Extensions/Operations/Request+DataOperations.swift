// Request+DataOperations.swift
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

#if os(iOS)
import UIKit
#endif

extension Request {
    /// Adds a request to a queue and starts a download process for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A Queue instance. If no queue is specified it uses the default one.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - onSuccess: specifies a success callback of type SuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type FailureCallback<T>.
    /// - returns: The Request object.
    @discardableResult
    public func start<T: Decodable>(queue: Queue? = Queue.shared,
                                    responseType: T.Type,
                                    onSuccess: SuccessCallback<T>?,
                                    onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue ?? Queue.shared

        dataTask = SessionTaskFactory.makeDataTask(with: self,
                                                   completionHandler: { data, urlResponse in
            let object: T!

            do {
                object = try data.deserializeJSONData(withKeyDecodingStrategy:
                                                        self.configuration.keyDecodingStrategy) as T
            } catch let error {
                let tnError = TNError.cannotDeserialize(String(describing: T.self), error)

                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             error: tnError,
                                             onFailureCallback: { onFailure?(tnError, data) })
                return
            }

            self.handleDataTaskCompleted(with: data,
                                         urlResponse: urlResponse,
                                         onSuccessCallback: { onSuccess?(object) })
        }, onFailure: { error, data in
            self.handleDataTaskCompleted(with: data,
                                         error: error,
                                         onFailureCallback: { onFailure?(error, data) })
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for Transformer types.
    ///
    /// - parameters:
    ///    - queue: A Queue instance. If no queue is specified it uses the default one.
    ///    - transformer: The transformer object that handles the transformation.
    ///    - onSuccess: specifies a success callback of type SuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type FailureCallback<T>.
    /// - returns: The Request object.
    @discardableResult
    public func start<FromType: Decodable, ToType>(queue: Queue? = Queue.shared,
                                                   transformer: Transformer<FromType, ToType>.Type,
                                                   onSuccess: SuccessCallback<ToType>?,
                                                   onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue ?? Queue.shared

        dataTask = SessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            let object: FromType!

            do {
                object = try data.deserializeJSONData(withKeyDecodingStrategy:
                                                        self.configuration.keyDecodingStrategy) as FromType
            } catch let error {
                let tnError = TNError.cannotDeserialize(String(describing: FromType.self), error)
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             error: tnError,
                                             onFailureCallback: { onFailure?(tnError, data) })
                return
            }

            // Transformation
            do {
                let object = try object.transform(with: transformer.init())

                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             onSuccessCallback: { onSuccess?(object) })

            } catch let error {
                guard let tnError = error as? TNError else {
                    return
                }
                self.handleDataTaskCompleted(with: data,
                                             error: tnError,
                                             onFailureCallback: { onFailure?(tnError, data) })
            }
        }, onFailure: { tnError, data in
            self.handleDataTaskCompleted(with: data,
                                         error: tnError,
                                         onFailureCallback: { onFailure?(tnError, data) })
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for UIImage|NSImage responses.
    ///
    /// - parameters:
    ///     - queue: A Queue instance. If no queue is specified it uses the default one.
    ///     - responseType: The response type is UIImage.self or NSImage.self.
    ///     - onSuccess: specifies a success callback of type SuccessCallback<T>.
    ///     - onFailure: specifies a failure callback of type FailureCallback<T>.
    /// - returns: The Request object.
    @discardableResult
    public func start<T: ImageType>(queue: Queue? = Queue.shared,
                                    responseType: T.Type,
                                    onSuccess: SuccessCallback<T>?,
                                    onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue

        dataTask = SessionTaskFactory.makeDataTask(with: self,
                                                   completionHandler: { data, urlResponse in
            let image = T(data: data)

            if image == nil {
                let tnError = TNError.responseInvalidImageData
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             error: tnError,
                                             onFailureCallback: { onFailure?(tnError, data) })

            } else {
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             onSuccessCallback: { onSuccess?(image ?? T()) })
            }
        }, onFailure: { tnError, data in
            self.handleDataTaskCompleted(with: data,
                                         error: tnError,
                                         onFailureCallback: { onFailure?(tnError, data) })
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for String responses.
    ///
    /// - parameters:
    ///    - queue: A Queue instance. If no queue is specified it uses the default one.
    ///    - responseType: The response type is String.self.
    ///    - onSuccess: specifies a success callback of type SuccessCallback<T>
    ///    - onFailure: specifies a failure callback of type FailureCallback<T>
    @discardableResult
    public func start(queue: Queue? = Queue.shared,
                      responseType: String.Type,
                      onSuccess: SuccessCallback<String>?,
                      onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue

        dataTask = SessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            DispatchQueue.main.async {
                if let string = String(data: data, encoding: .utf8) {

                    self.handleDataTaskCompleted(with: data,
                                                 urlResponse: urlResponse,
                                                 onSuccessCallback: { onSuccess?(string) })
                } else {
                    let tnError: TNError = .cannotConvertToString
                    self.handleDataTaskCompleted(with: data,
                                                 urlResponse: urlResponse,
                                                 error: tnError,
                                                 onFailureCallback: { onFailure?(tnError, data) })
                }

            }
        }, onFailure: { error, data in
            self.handleDataTaskCompleted(with: data,
                                         error: error,
                                         onFailureCallback: { onFailure?(error, data) })

        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for Data responses.
    ///
    /// - parameters:
    ///     - queue: A Queue instance. If no queue is specified it uses the default one.
    ///     - responseType: The response type is Data.self.
    ///     - onSuccess: specifies a success callback of type SuccessCallback<T>
    ///     - onFailure: specifies a failure callback of type FailureCallback<T>
    @discardableResult
    public func start(queue: Queue? = Queue.shared,
                      responseType: Data.Type,
                      onSuccess: SuccessCallback<Data>?,
                      onFailure: FailureCallback? = nil) -> Request {
        currentQueue = queue

        dataTask = SessionTaskFactory.makeDataTask(with: self,
                                                   completionHandler: { data, urlResponse in
            DispatchQueue.main.async {
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             onSuccessCallback: { onSuccess?(data) })
            }
        }, onFailure: { error, data in
            self.handleDataTaskCompleted(with: data,
                                         error: error,
                                         onFailureCallback: { onFailure?(error, data) })

        })

        currentQueue.addOperation(self)
        return self
    }
}
