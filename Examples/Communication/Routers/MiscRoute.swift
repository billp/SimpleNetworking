//
//  MiscRoute.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 14/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

enum MiscRoute: TNRouteProtocol {
    case testEncryptParams(param: String)

    func configure() -> TNRouteConfiguration {
        switch self {
        case .testEncryptParams(let value):
            return TNRouteConfiguration(
                method: .post,
                path: .path(["test_encrypt_params"]),
                params: ["value": value]
            )
        }
    }
}
