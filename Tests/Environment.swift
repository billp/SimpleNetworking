//
//  Environment.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import TermiNetwork

// swiftlint:disable function_body_length

enum Environment: TNEnvironmentProtocol {
    case httpHost
    case httpHostWithPort
    case httpHostWithPortAndSuffix
    case httpsHostWithPortAndSuffix
    case termiNetworkLocal
    case termiNetworkRemote
    case invalidHost
    case google

    func configure() -> TNEnvironment {
        let requestConfiguration = TNRequestConfiguration(cachePolicy: .returnCacheDataElseLoad,
                                                          timeoutInterval: 32,
                                                          requestBodyType: .JSON)

        let requestConfiguration2: TNRequestConfiguration = {
            let config = TNRequestConfiguration.default
            config.headers = ["Custom-Header": "dsadas"]
            return config
        }()

        switch self {
        case .httpHost:
            return TNEnvironment(scheme: .http,
                                 host: "localhost")
        case .httpHostWithPort:
            return TNEnvironment(scheme: .http,
                                 host: "localhost",
                                 suffix: nil,
                                 port: 8080)
        case .httpHostWithPortAndSuffix:
            return TNEnvironment(scheme: .http,
                                 host: "localhost",
                                 suffix: .path(["v1", "json"]),
                                 port: 8080)
        case .httpsHostWithPortAndSuffix:
            return TNEnvironment(scheme: .https,
                                 host: "google.com",
                                 suffix: .path(["v3", "test", "foo", "bar"]),
                                 port: 8080)
        case .termiNetworkLocal:
            return TNEnvironment(scheme: .http,
                                 host: "localhost",
                                 suffix: nil,
                                 port: 3000,
                                 configuration: requestConfiguration)
        case .termiNetworkRemote:
            return TNEnvironment(scheme: .https,
                                 host: "terminetwork-rails-app.herokuapp.com",
                                 configuration: requestConfiguration2)
        case .invalidHost:
            return TNEnvironment(scheme: .http,
                                 host: "localhostt",
                                 suffix: nil,
                                 port: 1234)
        case .google:
            return TNEnvironment(scheme: .https, host: "google.com")
        }
    }
}
