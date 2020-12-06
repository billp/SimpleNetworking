//
//  GlobalErrorHandler.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 2/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

class GlobalErrorHandler: TNErrorHandlerProtocol {
    static var failed = false
    static var skip = true

    func requestFailed(withResponse response: Data?, error: TNError, request: TNRequest) {
        GlobalErrorHandler.failed = true
    }

    func shouldHandleRequestFailure(withResponse response: Data?, error: TNError, request: TNRequest) -> Bool {
        !GlobalErrorHandler.skip
    }

    required init() { }
}
