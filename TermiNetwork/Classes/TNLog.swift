// TNLog.swift
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

import Foundation

internal class TNLog {
     static func logRequest(request: TNRequest) {
        guard TNEnvironment.verbose else { return }
        guard let urlRequest = try? request.asRequest() else { return }

        let url = urlRequest.url?.absoluteString ?? "n/a"
        let headers = urlRequest.allHTTPHeaderFields

        print("--------------------------------")
        print("🌎 URL: " + url)
        print("🎛️ Method: " + request.method.rawValue.uppercased())
        print("🔮 CURL Command: " + urlRequest.curlString)
        if let headers = headers, headers.keys.count > 0 {
            print("📃 Request Headers: " + headers.description)
        }
        if let params = request.params as [String: AnyObject]?,
            params.keys.count > 0,
            request.method != .get {
            if request.configuration.requestBodyType == .JSON {
                print("🗃️ Request Body: " + (params.toJSONString() ?? "[unknown]"))
            } else {
                print("🗃️ Request Body: " + params.description)
            }
        }

        if let customError = request.customError {
            print("❌ Error: " + (customError.localizedDescription ?? ""))
        } else if let response = request.urlResponse as? HTTPURLResponse {
            print("✅ Status: " + String(response.statusCode))
        }

        if let data = request.data {
            if let responseJSON = data.toJSONString() {
                print("📦 Response: " + responseJSON)
            } else if let stringResponse = String(data: data, encoding: .utf8) {
                print("📦 Response: " + (stringResponse.isEmpty ? "[empty-response]" : stringResponse))
            } else {
                print("📦 Response: [non-printable]")
            }
        }
    }
}
