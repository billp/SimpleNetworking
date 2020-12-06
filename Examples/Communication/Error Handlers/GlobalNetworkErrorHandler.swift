//
//  GlobalErrorHandler.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 6/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import UIKit
import TermiNetwork

class GlobalNetworkErrorHandler: TNErrorHandlerProtocol {
    func requestFailed(withResponse response: Data?, error: TNError, request: TNRequest) {
        if case .networkError(let error) = error {
            let alert = UIAlertController(title: NSLocalizedString("Network Error", comment: ""),
                                          message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.rootViewController?.present(alert, animated: false, completion: nil)
            }
        }
    }

    func shouldHandleRequestFailure(withResponse response: Data?, error: TNError, request: TNRequest) -> Bool {
        return true
    }

    // Add default initializer
    required init() { }
}
