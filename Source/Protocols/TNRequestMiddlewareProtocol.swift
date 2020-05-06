// TNRequestMiddlewareProtocol.swift
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

/// This protocol is used to register a middleware in order to modify body and headers of a request. (e.g.  it can be
/// used with  Crypto Swift library to encrypt or decrypt the data.
public protocol TNRequestMiddlewareProtocol {
    /// Modifies body params before they are sent to server
    ///   - parameters:
    ///     - params:  The body params that are constructed by TNRequest initializers
    ///   - returns:
    ///     - the new modified params
    func modifyBodyBeforeSend(with params: [String: Any?]?) throws -> [String: Any?]?

    /// Modifies data response before they are sent to callbacks
    ///   - parameters:
    ///     - data: The data
    ///   - returns:
    ///     - the new modified data
    func modifyBodyAfterReceive(with data: Data?) throws -> Data?

    /// Modifies the headers of the response before they are sent to server
    ///   - parameters:
    ///     - headers: the headers cosntructed by initializers and configuration
    ///   - returns:
    ///     - the new modified headers
    func modifyHeadersBeforeSend(with headers: [String: String]?) throws -> [String: String]?
}
