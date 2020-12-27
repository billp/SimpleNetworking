// CryptoMiddleware.swift
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

import TermiNetwork
import CryptoSwift

class CryptoMiddleware: RequestMiddlewareProtocol {
    fileprivate static let key = "aaaaaaaaaaaaaaaaaaaaaaabcdefg123"

    required init() { }

    func processParams(with params: [String: Any?]?) throws -> [String: Any?]? {
        if let params = params, let jsonString = params.toJSONString() {
            return ["data": try encryptedBase64(jsonString: jsonString)]
        }
        return nil
    }

    func processResponse(with data: Data?) throws -> Data? {
        guard let jsonDict = data?.toJSONDictionary(),
            let cipher = jsonDict["data"] as? String else {
            throw TNError.middlewareError("Invalid data")
        }
        return try decryptedData(base64StringCipher: cipher)
    }

    func processHeadersBeforeSend(with headers: [String: String]?) throws -> [String: String]? {
        headers
    }

    func processHeadersAfterReceive(with headers: [String: String]?) throws -> [String: String]? {
        var headers = headers
        headers?["X-Test-Header"] = "test123!"
        return headers
    }

    fileprivate func decryptedData(base64StringCipher: String) throws -> Data {
        guard let base64Data = Data(base64Encoded: base64StringCipher) else {
            throw TNError.middlewareError("Cannot decode base64 data to string")
        }
        do {
            let aes = try AES.init(key: CryptoMiddleware.key.bytes, blockMode: ECB())
            let data = Data(try aes.decrypt(base64Data.bytes))
            return data
        } catch {
            throw TNError.middlewareError("Cannot decrypt")
        }
    }

    fileprivate func encryptedBase64(jsonString: String) throws -> String {
        do {
            let aes = try AES.init(key: CryptoMiddleware.key.bytes, blockMode: ECB())
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
