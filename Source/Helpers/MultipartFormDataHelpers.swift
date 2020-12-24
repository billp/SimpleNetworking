// MultipartFormDataHelpers.swift
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

#if os(iOS)
import MobileCoreServices
#endif

class MultipartFormDataHelpers {
    fileprivate struct Constants {
        static let crlf = "\r\n"
    }
    /// Generates a random string that will be used as multipart boundary.
    static func generateBoundary() -> String {
        let randomString = String(Double.random(in: 0..<65535)).replacingOccurrences(of: ".", with: "")
        return randomString
    }

    /// Generates a Content-Disposition raw string to be added to multipart stream body.
    static func generateContentDisposition(boundary: String,
                                           name: String,
                                           filename: String? = nil,
                                           contentType: String? = nil) -> Data {
        var raw = "Content-Disposition: form-data; name=\"" + name + "\""
        if let filename = filename {
            raw += "; filename=\"\(filename)\""
        }
        raw += Constants.crlf

        if let contentType = contentType {
            raw += "Content-Type: \(contentType)" + Constants.crlf
        }

        raw += Constants.crlf

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
        var raw = Constants.crlf + "--" + boundary
        if isLastPart {
            raw += "--"
        }
        raw += Constants.crlf
        return raw.data(using: .utf8) ?? Data()
    }

    static func mimeTypeForPath(path: String) -> String? {
        let url = NSURL(fileURLWithPath: path)

        guard url.isFileURL else {
            return nil
        }

        let pathExtension = url.pathExtension

        #if !os(tvOS) && !os(watchOS)
        if let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        #endif
        return "application/octet-stream"
    }

    static func fileSize(withURL url: URL) -> Int {
        var attributes: [FileAttributeKey: Any]? {
            do {
                return try FileManager.default.attributesOfItem(atPath: url.path)
            } catch let error as NSError {
                print("FileAttribute error: \(error)")
            }
            return nil
        }

        return attributes?[.size] as? Int ?? 0
    }

    static func contentLength(forParams params: [String: MultipartFormDataPartType],
                              boundary: String) throws -> Int {
        var contentLength = openBodyPart(boundary: boundary).count

        try params.keys.enumerated().forEach { (index, key) in
            guard let value = params[key] else {
                throw TNError.invalidMultipartParams
            }
            let isLastPart = index == params.keys.count-1
            let closeBodyCount = closeBodyPart(boundary: boundary,
                                               isLastPart: isLastPart).count

            var filename: String?
            var contentType: String?

            if case .value(let value) = value {
                contentLength += (value.data(using: .utf8)?.count ?? 0)
            } else if case .data(let data, let fname, let ctype) = value {
                contentLength += data.count
                filename = fname ?? key
                contentType = ctype
            } else if case .url(let url) = value {
                contentLength += MultipartFormDataHelpers.fileSize(withURL: url)
                filename = url.lastPathComponent
                contentType = MultipartFormDataHelpers.mimeTypeForPath(path: url.path)
            }
            contentLength += closeBodyCount + generateContentDisposition(boundary: boundary,
                                                                         name: key,
                                                                         filename: filename,
                                                                         contentType: contentType).count
        }

        return contentLength
    }
}
