//
//  TNRequestBodyGenerators.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 3/5/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import UIKit

/// The body type of the request
public enum TNRequestBodyType: Equatable {
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

class TNRequestBodyGenerators {
    static func generateUrlEncodedString(with params: [String: Any?]) throws -> String {
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
        do {
            if let body = try params.toJSONData() {
                return body
            } else {
                throw TNError.invalidParams
            }
        } catch {
            throw TNError.invalidParams
        }
    }
}
