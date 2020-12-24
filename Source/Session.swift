// Session.swift
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

/// This is a custom implementation of URLSessionDelegate, used to handle certification pinning
internal final class Session<ResultType>: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {
    weak var request: Request?

    var receivedData: Data?

    var progressCallback: ProgressCallbackType?
    var completedCallback: ((ResultType?, URLResponse?, Error?) -> Void)?
    var failureCallback: FailureCallback?
    var inputStream: InputStream?

    init(with request: Request,
         progressCallback: ProgressCallbackType? = nil,
         completedCallback: ((ResultType?, URLResponse?, Error?) -> Void)? = nil,
         failureCallback: FailureCallback? = nil) {
        self.request = request
        self.progressCallback = progressCallback
        self.completedCallback = completedCallback
        self.failureCallback = failureCallback
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // Certificate pinning handling.
        let pinningManager = CertificatePinningManager(challenge: challenge,
                                                       completionHandler: completionHandler,
                                                       request: request)
        pinningManager.handleDidReceiveChallenge()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let tnError = TNError.networkError(error)

            failureCallback?(tnError, receivedData)
        } else {
            completedCallback?(receivedData as? ResultType, task.response, error)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if case .upload = request?.requestType, receivedData == nil {
            receivedData = Data()
        }
        receivedData?.append(data)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let streamDelegate = request?.multipartFormDataStream else {
            return
        }
        request?.multipartFormDataStream?.boundStreams.output.open()
        completionHandler(streamDelegate.boundStreams.input)
   }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        completedCallback?(location as? ResultType, nil, downloadTask.error)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let totalBytesWritten = Int(totalBytesWritten)
        let totalBytesExpectedToWrite = Int(totalBytesExpectedToWrite)
        let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)

        Log.logProgress(request: request,
                          bytesProcessed: totalBytesWritten,
                          totalBytes: totalBytesExpectedToWrite,
                          progress: progress)

        progressCallback?(Int(totalBytesWritten),
                          Int(totalBytesExpectedToWrite),
                          Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))
    }
}
