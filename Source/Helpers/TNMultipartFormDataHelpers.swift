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
                                           filename: String? = nil) -> Data {
        var raw = "Content-Disposition: form-data; name=\"" + name + "\""
        if let filename = filename {
            raw += "; filename=\"\(filename)\""
        }

        raw += Constants.crlf + Constants.crlf
        return raw.data(using: .utf8) ?? Data()
    }

    /// Opens a multipart stream body.
    static func openBodyPart(boundary: String) -> Data {
        let raw = "--" + boundary + Constants.crlf
        return raw.data(using: .utf8) ?? Data()
    }

    /// Closes a multipart stream body.
    static func closeBodyPart(boundary: String,
                              isLastPart: Bool) -> Data {
        var raw = Constants.crlf + "--"
        raw += boundary
        if isLastPart {
            raw += "--"
        }
        raw += Constants.crlf
        return raw.data(using: .utf8) ?? Data()
    }

    public static func contentLength(forParams params: [String: Any?],
                                     boundary: String) -> Int {
        var contentLength = openBodyPart(boundary: boundary).count

        params.keys.enumerated().forEach { (index, key) in
            let isLastPart = index == params.keys.count-1
            let closeBodyCount = closeBodyPart(boundary: boundary,
                                               isLastPart: isLastPart).count

            var fileName: String? = nil

            if let value = params[key] as? String {
                contentLength += (value.data(using: .utf8)?.count ?? 0)
            }
            if let data = params[key] as? Data {
                contentLength += data.count
                fileName = key
            }

            contentLength += closeBodyCount + generateContentDisposition(boundary: boundary,
                                                                         name: key,
                                                                         filename: fileName).count



        }

        return contentLength
    }
}
