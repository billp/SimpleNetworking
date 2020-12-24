// Data+Extensions.swift
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

/// Data extension for JSON deserialization.
public extension Data {
    ///
    /// Deserializes the JSON Data to the given type.
    /// - returns: The deserilized object.
    func deserializeJSONData<T>(
        withKeyDecodingStrategy keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil)
    throws -> T where T: Decodable {
        let jsonDecoder = JSONDecoder()
        if let keyDecodingStrategy = keyDecodingStrategy {
            jsonDecoder.keyDecodingStrategy = keyDecodingStrategy
        }
        return try jsonDecoder.decode(T.self, from: self)
    }

    ///
    /// Creates a JSON string (pretty printed) from Data.
    /// - returns: The pretty printed string.
    func toJSONString() -> String? {
        if let dictionary = try? JSONSerialization.jsonObject(with: self, options: []) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary,
                                                          options: .prettyPrinted),
                let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        return nil
    }

    internal func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
