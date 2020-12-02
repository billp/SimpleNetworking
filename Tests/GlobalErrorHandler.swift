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
    func requestFailed(withResponse response: Data?, error: TNError, request: TNRequest) {

    }

    func shouldHandleRequestFailure(withResponse response: Data?, error: TNError, request: TNRequest) -> Bool {
        true
    }
}
