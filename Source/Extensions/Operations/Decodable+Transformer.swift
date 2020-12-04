// Decodable+Transformer.swift
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

protocol TNTransformerProtocol: NSObject {
    associatedtype FromType
    associatedtype ToType

    func transform(_ object: FromType) -> ToType?
}

/// Use this class as super class to create your transformers.
/// You should pass FromType and ToType in your subclass definition.
/// Those types are used in transform function.
open class TNTransformer<FromType, ToType>: NSObject, TNTransformerProtocol {
    /// This is the default transform method. This method should be overriden by subclass
    ///
    /// - parameters:
    ///    - object: The object that will be transformed
    /// - returns: The transformed object
    open func transform(_ object: FromType) -> ToType? {
        return nil
    }
}

public extension Decodable {
    func transform<FromType, ToType>(with transformer: TNTransformer<FromType, ToType>) -> ToType? {
        guard let object = self as? FromType else {
            return nil
        }
        return transformer.transform(object)
    }
}
