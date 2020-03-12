//
//  Environment.swift
//  SimpleNetworking_Example
//
//  Created by Vasilis Panagiotopoulos on 14/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import TermiNetwork

enum Environment: TNEnvironmentProtocol {
    case localhost
    case dev
    case production

    func configure() -> TNEnvironment {
        let requestConfiguration = TNRequestConfiguration(cachePolicy: .useProtocolCachePolicy,
                                                          timeoutInterval: 30,
                                                          requestBodyType: .JSON)
        switch self {
        case .localhost:
            return TNEnvironment(scheme: .https,
                                 host: "localhost",
                                 port: 8080,
                                 requestConfiguration: requestConfiguration)
        case .dev:
            return TNEnvironment(scheme: .https,
                                 host: "mydevserver.com",
                                 suffix: .path(["v1"]),
                                 requestConfiguration: requestConfiguration)
        case .production:
            return TNEnvironment(scheme: .http,
                                 host: "www.themealdb.com",
                                 suffix: .path(["api", "json", "v1", "1"]),
                                 requestConfiguration: requestConfiguration)
        }
    }
}
