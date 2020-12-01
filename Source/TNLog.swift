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
// swiftlint:disable cyclomatic_complexity
import Foundation

internal class TNLog {
    enum State {
        case started
        case finished
    }

    // swiftlint:disable function_body_length
    static func logRequest(request: TNRequest?,
                           data: Data?,
                           state: State = .finished,
                           urlResponse: URLResponse?,
                           tnError: TNError?) {
                guard let request = request else { return }
        guard request.configuration.verbose == true else {
            TNLog.printSimpleErrorIfNeeded(tnError)
            return
        }
        guard let urlRequest = try? request.asRequest() else {
            TNLog.printSimpleErrorIfNeeded(tnError)
            return
        }
        DispatchQueue.main.async {
            let url = urlRequest.url?.absoluteString ?? "n/a"
            let headers = urlRequest.allHTTPHeaderFields

            print(String(format: "🌎 URL: %@", url))
            if request.configuration.useMockData == true {
                print("🗂 Uses mock data")
            }
            print(String(format: "🎛️ Method: %@", request.method.rawValue.uppercased()))
            if case .data = request.requestType {
                print(String(format: "🔮 CURL: %@", urlRequest.curlString))
            }

            if request.configuration.certificateData != nil {
                print("🔒 Pinning Enabled")
            }

            if let headers = headers, headers.keys.count > 0 {
                print(String(format: "📃 Request Headers: %@", headers.description))
            }
            if let params = request.params as [String: AnyObject]?,
                params.keys.count > 0,
                request.method != .get {
                if request.configuration.requestBodyType == .JSON {
                    print(String(format: "🗃️ Request Body: %@", (params.toJSONString() ?? "[unknown]")))
                } else if request.multipartFormDataStream != nil {
                    print("🗃️ Request Body: [multipart/form-data]")
                } else {
                    print(String(format: "🗃️ Request Body: %@", params.description))
                }
            }

            if let customError = tnError {
                print(String(format: "❌ Error: %@", (customError.localizedDescription ?? "")))
            } else if let response = urlResponse as? HTTPURLResponse {
                print(String(format: "✅ Status: %@", String(response.statusCode)))
            }

            if let data = data {
                if let responseJSON = data.toJSONString() {
                    print(String(format: "📦 Response: %@", responseJSON))
                } else if let stringResponse = String(data: data, encoding: .utf8) {
                    print(String(format: "📦 Response: %@", (stringResponse.isEmpty ? "[empty-response]" : stringResponse)))
                } else {
                    print("📦 Response: [non-printable]")
                }
            } else if case .download(let destinationPath) = request.requestType,
                      case .finished = state, tnError == nil {
                print(String(format: "📦 File saved to: '%@'", destinationPath))
            }

            switch state {
            case .started:
                print("🚀 Request Started...\n")
            case .finished:
                print("🏁 Request finished.\n")
            }
            }
    }

    static func logProgress(request: TNRequest?,
                            bytesProcessed: Int,
                            totalBytes: Int,
                            progress: Float) {
        guard request?.configuration.verbose == true else { return }

        print(String(format: "⌛️ Bytes processed: %d of %d, Progress: %f",
                     bytesProcessed,
                     totalBytes,
                     progress))
    }

    static func printSimpleErrorIfNeeded(_ tnError: TNError?) {
        if let localizedError = tnError?.localizedDescription {
            print(String(format: "❌ Error: %@", localizedError))
        }
    }
}
