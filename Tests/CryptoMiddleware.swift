//
//  CryptoMiddleware.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 21/4/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import UIKit
import TermiNetwork
import CryptoSwift

class CryptoMiddleware: TNRequestMiddlewareProtocol {
    fileprivate static let key = "aaaaaaaaaaaaaaaaaaaaaaabcdefg123"

    func modifyBodyBeforeSend(with params: [String: Any?]?) throws -> [String: Any?]? {
        return params
    }

    func modifyBodyAfterReceive(with data: Data?) throws -> Data? {
        guard let jsonDict = data?.toJSONDictionary(),
            let cipher = jsonDict["data"] as? String else {
            throw TNError.middlewareError("Invalid data")
        }
        return try decryptedData(base64StringCipher: cipher)
    }

    func modifyHeadersBeforeSend(with headers: [String: String]?) throws -> [String: String]? {
        return headers
    }

    fileprivate func decryptedData(base64StringCipher: String) throws -> Data {
        guard let base64Data = Data(base64Encoded: base64StringCipher) else {
            throw TNError.middlewareError("Cannot decode base64 data to string")
        }

        do {
            let aes = try AES.init(key: CryptoMiddleware.key.bytes, blockMode: CBC(iv: <#Array<UInt8>#>))
            let data = Data(try aes.decrypt(base64Data.bytes))
            print(String(data: data, encoding: .utf8))
            return data
        } catch {
            throw TNError.middlewareError("Cannot decrypt")
        }
    }
}

fileprivate extension Data {
    func toJSONDictionary() -> [String: AnyObject]? {
        return try? JSONSerialization.jsonObject(with: self, options: []) as? [String: AnyObject]
    }
}
