// TNQueue.swift
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
        let requestConfiguration = TNConfiguration(cachePolicy: .returnCacheDataElseLoad,
                                                          timeoutInterval: 32,
                                                          requestBodyType: .JSON)

        let requestConfiguration2: TNConfiguration = {
            let config = TNConfiguration(cachePolicy: .useProtocolCachePolicy,
                                         timeoutInterval: 60,
                                         requestBodyType: .xWWWFormURLEncoded)
            config.verbose = true
            config.headers = ["Custom-Header": "dsadas"]
            config.errorHandlers = [GlobalErrorHandler()]
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
