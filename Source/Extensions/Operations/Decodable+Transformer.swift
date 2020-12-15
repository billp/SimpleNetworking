// Decodable+Transformer.swift
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

private protocol TNTransformerProtocol: NSObject {
    associatedtype FromType
    associatedtype ToType

    func transform(_ object: FromType) throws -> ToType
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
    open func transform(_ object: FromType) throws -> ToType {
        fatalError("You must override this method.")
    }

    /// Default initializer
    required public override init() { }
}

public extension Decodable {
    /// Transforms the decodable object with the specified transformer.
    ///
    /// - parameters:
    ///    - transformer: The transformer object that handles the transformation.
    /// - returns: The transformed object
    func transform<FromType, ToType>(with transformer: TNTransformer<FromType, ToType>) throws -> ToType {
        guard let object = self as? FromType else {
            throw TNError.transformationFailed
        }
        return try transformer.transform(object)
    }
}
