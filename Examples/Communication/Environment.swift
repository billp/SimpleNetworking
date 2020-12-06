//
//  Environment.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 1/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

enum Environment: TNEnvironmentProtocol {
    case heroku

    func configure() -> TNEnvironment {
        switch self {
        case .heroku:
            return TNEnvironment(scheme: .https,
                                 host: "terminetwork-rails-app.herokuapp.com",
                                 configuration: defaultConfiguration)
        }
    }

    private var defaultConfiguration: TNConfiguration {
        let configuration = TNConfiguration()
        configuration.keyDecodingStrategy = .convertFromSnakeCase
        configuration.verbose = true
        configuration.errorHandlers = [GlobalNetworkErrorHandler.self]
        if let path = Bundle.main.path(forResource: "MockData", ofType: "bundle") {
            configuration.mockDataBundle = Bundle(path: path)
        }
        return configuration
    }
}
