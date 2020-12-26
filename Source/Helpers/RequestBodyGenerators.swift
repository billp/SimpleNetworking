// RequestBodyGenerators.swift
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

/// The body type of the request
public enum RequestBodyType: Equatable {
    /// The request params are sent as application/x-www-form-urlencoded mime type
    case xWWWFormURLEncoded
    /// The request params are sent as application/json mime type
    case JSON
    /// Type for multipart/form-data body by giving the boundary as String. Typically you don't have to set it manually
    /// since it is set automatically by upload requests.
    case multipartFormData(boundary: String)

    func value() -> String {
        switch self {
        case .xWWWFormURLEncoded:
            return "application/x-www-form-urlencoded"
        case .JSON:
            return "application/json"
        case .multipartFormData(let boundary):
            return  "multipart/form-data; boundary=\(boundary)"
        }
    }
}

class RequestBodyGenerator {
    static func generateURLEncodedString(with params: [String: Any?]) throws -> String {
        // Create query string from the given params
        let queryString = try params.filter({ $0.value != nil }).map { param -> String in
            if let value = String(describing: param.value!)
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                return param.key + "=" + value
            } else {
                throw TNError.invalidParams
            }
        }.joined(separator: "&")

        return queryString
    }

    static func generateJSONBodyData(with params: [String: Any?]) throws -> Data {
        guard let body = try params.toJSONData() else {
            throw TNError.invalidParams
        }
        return body
    }
}
