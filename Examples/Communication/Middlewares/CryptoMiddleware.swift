//
//  CryptoMiddleware.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 21/4/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import TermiNetwork
import CryptoSwift

class CryptoMiddleware: TNRequestMiddlewareProtocol {
    required init() { }

    static var encryptionKey = "aaaaaaaaaaaaaaaaaaaaaaabcdefg123"
    static var decryptionKey = "aaaaaaaaaaaaaaaaaaaaaaabcdefg123"

    func modifyBodyBeforeSend(with params: [String: Any?]?) throws -> [String: Any?]? {
        if let params = params, let jsonString = params.toJSONString() {
            return ["data": try encryptedBase64(jsonString: jsonString)]
        }
        return nil
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
            let aes = try AES.init(key: CryptoMiddleware.decryptionKey.bytes, blockMode: ECB())
            let data = Data(try aes.decrypt(base64Data.bytes))
            return data
        } catch {
            throw TNError.middlewareError("Cannot decrypt")
        }
    }

    fileprivate func encryptedBase64(jsonString: String) throws -> String {
        do {
            let aes = try AES.init(key: CryptoMiddleware.encryptionKey.bytes, blockMode: ECB())
            let data = Data(try aes.encrypt(jsonString.bytes))
            return data.base64EncodedString()
        } catch {
            throw TNError.middlewareError("Cannot encrypt")
        }
    }

}

fileprivate extension Data {
    func toJSONDictionary() -> [String: AnyObject]? {
        return try? JSONSerialization.jsonObject(with: self, options: []) as? [String: AnyObject]
    }

    func toJSONString() -> String? {
        if let dictionary = try? JSONSerialization.jsonObject(with: self, options: []) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary,
                                                          options: .prettyPrinted),
                let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        return nil
    }
}

fileprivate extension Dictionary {
    func toJSONData() throws -> Data? {
        return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }

    func toJSONString() -> String? {
        return try? self.toJSONData()?.toJSONString()
    }
}
