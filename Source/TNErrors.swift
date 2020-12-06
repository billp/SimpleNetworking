// TNErrors.swift
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

// swiftlint:disable line_length

import Foundation

/// Custom error definition.
public enum TNError: Error {
    /// Thrown when the url is not valid.
    case invalidURL
    /// Thrown when the environment is not set.
    case environmentNotSet
    /// Thrown when the params contain invalid characters.
    case invalidParams
    /// Thrown when the response object is expected to be a UIImage but it's not.
    case responseInvalidImageData
    /// Thrown when the given Codable type cannot be deserialized. It contains the className and the error about deserilization.
    /// was went wrong in parsing.
    case cannotDeserialize(String, Error)
    /// Thrown when the response object is expected to be a String but it's not.
    case cannotConvertToString
    /// Thrown when a network error occured. It contains the NSURLError.
    case networkError(Error)
    /// Thrown when a request is not succeeded (it's not 2xx). It contains the HTTP Status Code.
    case notSuccess(Int)
    /// Thrown when a request is canceled.
    case canceled(Error)
    /// Thrown when a request is mocked but the data is invalid (e.g. cannot parse JSON).
    case invalidMockData(String)
    /// Thrown when a middleware reports an error. It contains a custom type
    case middlewareError(Any)
    /// Thrown when TNMultipartFormDataPartType param is expected but passed something else.
    case invalidMultipartParams
    /// Thrown when an invalid file path URL is passed on upload/download operations.
    case invalidFileURL(String)
    /// Thrown when the file cannot be saved to destination for some reason.
    /// It contains the Error with additional information.
    case downloadedFileCannotBeSaved(Error)
    /// Thrown when the transform method is not implemented (overriden in subclass).
    case transformerNotImplemented
    /// Thrown when the transformation failed for some reason, e.g. Incompatible Types
    case transformationFailed
}

extension TNError: LocalizedError {
    public var localizedDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("The URL is invalid", comment: "TNError")
        case .environmentNotSet:
            return NSLocalizedString("Environment not set, add the 'TNEnvironment.set(<Environment>)' method call in your AppDelegate application(_:didFinishLaunchingWithOptions:) method.", comment: "TNError")
        case .invalidParams:
            return NSLocalizedString("The parameters are not valid", comment: "TNError")
        case .responseInvalidImageData:
            return NSLocalizedString("The response data is not a valid image", comment: "TNError")
        case .cannotDeserialize(let className, let error):
            let debugDescription = (error as NSError).userInfo["NSDebugDescription"] as? String ?? ""
            var errorKeys = ""
            if let codingPath = (error as NSError).userInfo["NSCodingPath"] as? [CodingKey] {
                errorKeys = (codingPath.count > 0 ? " Key(s): " : "") + codingPath.map({
                    $0.stringValue
                }).joined(separator: ", ")
            }
            let fullDescription = String(format: "className: %@. %@%@", className, debugDescription, errorKeys)
            return NSLocalizedString("Cannot deserialize: ", comment: "TNError") + fullDescription
        case .networkError(let error):
                return NSLocalizedString("Network error: ", comment: "TNError") + error.localizedDescription
        case .cannotConvertToString:
            return NSLocalizedString("Cannot convert to String", comment: "TNError")
        case .notSuccess(let code):
            return String(format: NSLocalizedString("The request returned a not success status code: %i", comment: "TNError"), code)
        case .canceled(let error):
            return NSLocalizedString("The request has been canceled: ", comment: "TNError") + error.localizedDescription
        case .invalidMockData(let path):
            return String(format: NSLocalizedString("Invalid mock data file: '%@'", comment: "TNError"), path)
        case .middlewareError(let error):
            return String(format: NSLocalizedString("Middleware error: %@", comment: "TNError"), String(describing: error))
        case .invalidMultipartParams:
            return NSLocalizedString("Parameters are invalid. Expected parameters of type TNMultipartFormDataPartType.", comment: "TNError")
        case .invalidFileURL(let path):
            return String(format: NSLocalizedString("File path %@ is not valid.", comment: "TNError"), path)
        case .downloadedFileCannotBeSaved(let error):
            return String(format: NSLocalizedString("File save error: %@.", comment: "TNError"), error.localizedDescription)
        case .transformerNotImplemented:
            return NSLocalizedString("Transformer not implemented.", comment: "TNError")
        case .transformationFailed:
            return NSLocalizedString("Transormation Failed.", comment: "TNError")
        }
    }
}
