// GlobalNetworkErrorHandler.swift
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
import UIKit
import TermiNetwork

final class ServiceErrorInterceptor: InterceptorProtocol {
    let retryDelay: TimeInterval = 0

    func requestFinished(responseData data: Data?,
                         error: TNError?,
                         request: Request,
                         proceed: @escaping (InterceptionAction) -> Void) {

        // Show a retry dialog on network error and on server error 500
        switch error {
        case .networkError(let error):
            showRetryDialog(errorMessage: error.localizedDescription) {
                proceed(.retry(delay: self.retryDelay))
            }
            break
        case .notSuccess(let statusCode):
            showRetryDialog(
                errorMessage: NSLocalizedString(String(format: "Server Error (%i) please try again.", statusCode),
                                                comment: "")) {
                proceed(.retry(delay: self.retryDelay))
            }
            break
        default:
            proceed(.continue)
        }
    }

    func showRetryDialog(errorMessage: String, retryAction: @escaping () -> Void) {
        let alert = UIAlertController(title: NSLocalizedString("Something went wrong", comment: ""),
                                      message: errorMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
            retryAction()
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.first?.rootViewController?.present(alert, animated: false, completion: nil)
        }
    }

}
