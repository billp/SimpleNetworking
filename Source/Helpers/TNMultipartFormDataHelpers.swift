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
        static let crlf = "\r\n"
    }
    /// Generates a random string that will be used as multipart boundary.
    public static func generateBoundary() -> String {
        let randomString = String(Double.random(in: 0..<65535)).replacingOccurrences(of: ".", with: "")
        return randomString
    }

    /// Generates a Content-Disposition raw string to be added to multipart stream body.
    static func generateContentDisposition(boundary: String,
                                           name: String,
                                           filename: String? = nil) -> String {
        var rawString = "Content-Disposition: form-data; name=\"" + name + "\""
        if let filename = filename {
            rawString += "; filename=\"\(filename)\""
        }
        return rawString + Constants.crlf + Constants.crlf
    }

    /// Opens a multipart stream body.
    static func openBodyPart(boundary: String) -> String {
        "--" + boundary + Constants.crlf
    }

    /// Closes a multipart stream body.
    static func closeBodyPart(boundary: String) -> String {
        return Constants.crlf + "--" + boundary + "--"
    }

    public static func contentLength(forParams params: [String: Any?],
                                     boundary: String) -> Int {
        let stringOpenBodyCount = openBodyPart(boundary: boundary).data(using: .utf8)?.count ?? 0
        let stringCloseBodyCount = closeBodyPart(boundary: boundary).data(using: .utf8)?.count ?? 0

        var contentLength = stringOpenBodyCount + stringCloseBodyCount

        params.keys.forEach { key in
            let dispositionCount = generateContentDisposition(boundary: boundary,
                                                         name: key).data(using: .utf8)?.count ?? 0

            if let value = params[key] as? String {
                contentLength += dispositionCount + (value.data(using: .utf8)?.count ?? 0)
            }
            if let data = params[key] as? Data {
                contentLength += dispositionCount + data.count
            }
        }

        return contentLength
    }
}
