// CertificatePinningManager.swift
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

class CertificatePinningManager {
    var challenge: URLAuthenticationChallenge
    var completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    weak var request: Request?

    init(challenge: URLAuthenticationChallenge,
         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void,
         request: Request?) {
        self.challenge = challenge
        self.completionHandler = completionHandler
        self.request = request
    }

    func handleDidReceiveChallenge() {
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
            if isServerTrusted && error == nil && certData.contains(remoteCertificateData) {
                challengeDisposition = .useCredential
            } else {
                request?.pinningErrorOccured = true
            }
        } else {
            challengeDisposition = .performDefaultHandling
        }
        completionHandler(challengeDisposition,
                          URLCredential(trust: serverTrust))
    }
}
