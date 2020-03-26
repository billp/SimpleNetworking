// TNSessuib.swift
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

class TNSession: NSObject, URLSessionDelegate {
    weak var request: TNRequest!

    init(withTNRequest request: TNRequest) {
        self.request = request
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        var challengeDisposition: URLSession.AuthChallengeDisposition = .cancelAuthenticationChallenge
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if let certData = request.configuration.certificateData,
            let remoteCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
            let policies = NSMutableArray()
            policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)))
            SecTrustSetPolicies(serverTrust, policies)

            // Evaluate server certificate
            var result: SecTrustResultType = SecTrustResultType(rawValue: 0)!
            SecTrustEvaluate(serverTrust, &result)
            let isServerTrusted = result ==  SecTrustResultType.proceed

            let remoteCertificateData: NSData = SecCertificateCopyData(remoteCert)
            if isServerTrusted && remoteCertificateData.isEqual(to: certData as Data) {
                challengeDisposition = .useCredential
            }
        } else {
            challengeDisposition = .performDefaultHandling
        }

        completionHandler(challengeDisposition, URLCredential(trust: serverTrust)
)
    }
}
