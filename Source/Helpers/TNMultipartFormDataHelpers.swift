//
//  TNMultipartFormDataHelpers.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 4/5/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//
import MobileCoreServices

class TNMultipartFormDataHelpers {
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

    static func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

    public static func fileSize(withURL url: URL) -> Int {
        guard let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = resources.fileSize else {
            return -1
        }
        return fileSize
    }

    public static func contentLength(forParams params: [String: TNMultipartFormDataPartType],
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
                contentLength += TNMultipartFormDataHelpers.fileSize(withURL: url)
                filename = url.lastPathComponent
                contentType = TNMultipartFormDataHelpers.mimeTypeForPath(path: url.path)
            }
            contentLength += closeBodyCount + generateContentDisposition(boundary: boundary,
                                                                         name: key,
                                                                         filename: filename,
                                                                         contentType: contentType).count
        }

        return contentLength
    }
}
