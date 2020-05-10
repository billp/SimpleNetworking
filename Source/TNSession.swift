// TNSession.swift
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

import UIKit

/// This is a custom implementation of URLSessionDelegate, used to handle certification pinning
class TNSession: NSObject, URLSessionDataDelegate {
    weak var request: TNRequest?

    var receivedData: Data?

    var uploadProgressCallback: TNProgressCallbackType?
    var completedCallback: ((Data?, URLResponse?, Error?) -> Void)?
    var failureCallback: TNFailureCallback?
    var inputStream: InputStream?

    init(with request: TNRequest,
         uploadProgressCallback: TNProgressCallbackType? = nil,
         completedCallback: ((Data?, URLResponse?, Error?) -> Void)? = nil,
         failureCallback: TNFailureCallback? = nil) {
        self.request = request
        self.uploadProgressCallback = uploadProgressCallback
        self.completedCallback = completedCallback
        self.failureCallback = failureCallback

        if uploadProgressCallback != nil {
            receivedData = Data()
        }
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        var challengeDisposition: URLSession.AuthChallengeDisposition = .cancelAuthenticationChallenge
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if let certData = request?.configuration.certificateData,
            let remoteCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
            let policies = NSMutableArray()
            policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)))
            SecTrustSetPolicies(serverTrust, policies)

            // Evaluate server certificate
            var error: CFError?
            let isServerTrusted = SecTrustEvaluateWithError(serverTrust, &error)

            let remoteCertificateData: NSData = SecCertificateCopyData(remoteCert)
            if isServerTrusted && error == nil && remoteCertificateData.isEqual(to: certData as Data) {
                challengeDisposition = .useCredential
            }
        } else {
            challengeDisposition = .performDefaultHandling
        }
        completionHandler(challengeDisposition,
                          URLCredential(trust: serverTrust))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            failureCallback?(.networkError(error), receivedData)
        } else {
            completedCallback?(receivedData, task.response, error)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData?.append(data)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let streamDelegate = request?.multipartFormDataStream else {
            return
        }
        completionHandler(streamDelegate.boundStreams.input)
   }
}
