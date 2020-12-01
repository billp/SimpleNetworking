//
//  CitiesRouter.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 1/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

enum CityRoute: TNRouteProtocol {
    case cities

    func configure() -> TNRouteConfiguration {
        switch self {
        case .cities:
            return TNRouteConfiguration(method: .get, path: .path(["cities"]))
        }
    }
}
