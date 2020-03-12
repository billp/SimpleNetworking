//
//  TNErrors.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 25/02/2018.
//  Copyright © 2018 Vasilis Panagiotopoulos. All rights reserved.
//

import Foundation

// Errors before execution of a request
public enum TNError: Error {
    case invalidURL
    case environmentNotSet
    case invalidParams
    case responseDataIsEmpty
    case responseInvalidImageData
    case cannotDeserialize(Error)
    case cannotConvertToString
    case networkError(Error)
    case notSuccess(Int)
    case cancelled(Error)
}

extension TNError: LocalizedError {
    public var localizedDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("The URL is invalid", comment: "TNError")
        case .environmentNotSet:
            return NSLocalizedString("Environment not set, use TNEnvironment.set(YOUR_ENVIRONMENT)", comment: "TNError")
        case .invalidParams:
            return NSLocalizedString("The parameters are not valid", comment: "TNError")
        case .responseDataIsEmpty:
            return NSLocalizedString("The response data is empty. Set TNRequest.allowEmptyResponseBody to true get rid of this error", comment: "TNError")
        case .responseInvalidImageData:
            return NSLocalizedString("The response data is not a valid image", comment: "TNError")
        case .cannotDeserialize(let error):
            let debugDescription = (error as NSError).userInfo["NSDebugDescription"] as! String
            var errorKeys = ""
            if let codingPath = (error as NSError).userInfo["NSCodingPath"] as? [CodingKey] {
                errorKeys = (codingPath.count > 0 ? " Key(s): " : "") + codingPath.map({
                    $0.stringValue
                }).joined(separator: ", ")
            }
            let fullDescription = "\(debugDescription)\(errorKeys)"
            return NSLocalizedString("Cannot deserialize object: ", comment: "TNError") + fullDescription
        case .networkError(let error):
                return NSLocalizedString("Network error: ", comment: "TNError") + error.localizedDescription
        case .cannotConvertToString:
            return NSLocalizedString("Cannot convert to String", comment: "TNError")
        case .notSuccess(let code):
            return String(format: NSLocalizedString("The request didn't return 2xx status code but %i instead", comment: "TNError"), code)
        case .cancelled(let error):
            return NSLocalizedString("The request has been cancelled: ", comment: "TNError") + error.localizedDescription
        }
    }
}
