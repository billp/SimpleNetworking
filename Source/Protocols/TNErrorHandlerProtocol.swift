// TNErrorHandlerProtocol.swift
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

/// Use this protocol to create error handlers that can be passed to TNConfiguration instances.
/// Every class that implements this protocol will be used to handle errors when a request is failed.
public protocol TNErrorHandlerProtocol: class {
    /// This function is called when a request is failed.
    ///   - parameters:
    ///     - response: The deserialized error object
    ///     - error: The TNError provided by Terminetwork
    ///     - request: The TNRequest object
    func requestFailed(withResponse response: Data?, error: TNError, request: TNRequest)

    /// This function returns a Boolean for whether the requestFailed function will be executed.
    ///   - parameters:
    ///     - response: The deserialized error object
    ///     - error: The TNError provided by Terminetwork
    ///     - request: The TNRequest object
    func shouldHandleRequestFailure(withResponse response: Data?, error: TNError, request: TNRequest) -> Bool

    /// Default initializer
    init()
}
