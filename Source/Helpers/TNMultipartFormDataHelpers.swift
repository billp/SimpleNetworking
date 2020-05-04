//
//  TNMultipartFormDataHelpers.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 4/5/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import UIKit

public class TNMultipartFormDataHelpers {
    fileprivate struct Constants {
        static let CRLF = "\r\n"
    }
    /// Generates a random string that will be used as multipart boundary.
    public static func generateBoundary() -> String {
        let randomString = String(Double.random(in: 0..<65535)).replacingOccurrences(of: ".", with: "")
        return String(format: "--------------------------\(randomString)")
    }

    /// Generates a Content-Disposition raw string to be added to multipart stream body.
    static func generateContentDisposition(boundary: String,
                                           name: String,
                                           filename: String? = nil) -> String {
        var rawString = "Content-Disposition: form-data; name=\"" + name + "\""
        if let filename = filename {
            rawString += "; filename=\"\(filename)\""
        }
        return rawString + Constants.CRLF + Constants.CRLF
    }

    public static func contentLength(forParams params: [String: Any?],
                                     boundary: String) -> Int {
        var contentLength = 0

        params.keys.forEach { key in
            if let value = params[key] as? String {
                let disposition = generateContentDisposition(boundary: boundary,
                                                             name: key) +
                                                                Constants.CRLF +
                                                                boundary
                contentLength += disposition.count + value.count
            }
            if let data = params[key] as? Data {
                let disposition = generateContentDisposition(boundary: boundary,
                                                             name: key) +
                                                                Constants.CRLF +
                                                                boundary
                contentLength += disposition.count + data.count
            }
        }

        return contentLength
    }
}
