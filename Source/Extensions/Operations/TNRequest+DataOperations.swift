// TNRequest+DataOperations.swift
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

#if os(iOS)
import UIKit
#endif

extension TNRequest {
    /// Adds a request to a queue and starts a download process for Decodable types.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - responseType:The type of the model that will be deserialized and will be passed to the success block.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    /// - returns: The TNRequest object.
    @discardableResult
    public func start<T: Decodable>(queue: TNQueue? = TNQueue.shared,
                                    responseType: T.Type,
                                    onSuccess: TNSuccessCallback<T>?,
                                    onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue ?? TNQueue.shared

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
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
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - transformer: The transformer object that handles the transformation.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    /// - returns: The TNRequest object.
    @discardableResult
    public func start<FromType: Decodable, ToType>(queue: TNQueue? = TNQueue.shared,
                                                   transformer: TNTransformer<FromType, ToType>.Type,
                                                   onSuccess: TNSuccessCallback<ToType>?,
                                                   onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue ?? TNQueue.shared

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
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

    /// Adds a request to a queue and starts its execution for UIImage|NSImage responses.
    ///
    /// - parameters:
    ///     - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///     - responseType: The response type is UIImage.self or NSImage.self.
    ///     - onSuccess: specifies a success callback of type TNSuccessCallback<T>.
    ///     - onFailure: specifies a failure callback of type TNFailureCallback<T>.
    /// - returns: The TNRequest object.
    @discardableResult
    public func start<T: TNImageType>(queue: TNQueue? = TNQueue.shared,
                                      responseType: T.Type,
                                      onSuccess: TNSuccessCallback<T>?,
                                      onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            let image = T(data: data)

            if image == nil {
                let tnError = TNError.responseInvalidImageData
                self.handleDataTaskFailure(with: data,
                                           urlResponse: nil,
                                           tnError: tnError,
                                           onFailure: onFailure)
            } else {
                onSuccess?(image ?? T())
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: nil,
                                             tnError: nil)
            }
        }, onFailure: { tnError, data in
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError,
                                       onFailure: onFailure)
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for String responses.
    ///
    /// - parameters:
    ///    - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///    - responseType: The response type is String.self.
    ///    - onSuccess: specifies a success callback of type TNSuccessCallback<T>
    ///    - onFailure: specifies a failure callback of type TNFailureCallback<T>
    @discardableResult
    public func start(queue: TNQueue? = TNQueue.shared,
                      responseType: String.Type,
                      onSuccess: TNSuccessCallback<String>?,
                      onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            DispatchQueue.main.async {
                if let string = String(data: data, encoding: .utf8) {
                    onSuccess?(string)
                    self.handleDataTaskCompleted(with: data,
                                                 urlResponse: urlResponse,
                                                 tnError: nil)
                } else {
                    let tnError = TNError.cannotConvertToString
                    self.handleDataTaskFailure(with: data,
                                               urlResponse: nil,
                                               tnError: tnError,
                                               onFailure: onFailure)
                }

            }
        }, onFailure: { tnError, data in
            self.handleDataTaskFailure(with: data,
                                       urlResponse: nil,
                                       tnError: tnError,
                                       onFailure: onFailure)
        })

        currentQueue.addOperation(self)
        return self
    }

    /// Adds a request to a queue and starts its execution for Data responses.
    ///
    /// - parameters:
    ///     - queue: A TNQueue instance. If no queue is specified it uses the default one.
    ///     - responseType: The response type is Data.self.
    ///     - onSuccess: specifies a success callback of type TNSuccessCallback<T>
    ///     - onFailure: specifies a failure callback of type TNFailureCallback<T>
    @discardableResult
    public func start(queue: TNQueue? = TNQueue.shared,
                      responseType: Data.Type,
                      onSuccess: TNSuccessCallback<Data>?,
                      onFailure: TNFailureCallback? = nil) -> TNRequest {
        currentQueue = queue

        dataTask = TNSessionTaskFactory.makeDataTask(with: self,
                                                     completionHandler: { data, urlResponse in
            DispatchQueue.main.async {
                onSuccess?(data)
                self.handleDataTaskCompleted(with: data,
                                             urlResponse: urlResponse,
                                             tnError: nil)
            }
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
