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
    case city(id: Int)
    case thumb(city: City)
    case image(city: City)

    func configure() -> TNRouteConfiguration {
        switch self {
        case .cities:
            return TNRouteConfiguration(method: .get,
                                        path: .path(["cities"]),
                                        mockFilePath:
                                            .path(["Cities", "cities.json"]))
        case .city(let id):
            return TNRouteConfiguration(method: .get,
                                        path: .path(["city", String(id)]),
                                        mockFilePath:
                                            .path(["Cities", "Details", String(format: "%i.json", id)]))
        case .thumb(let city):
            return TNRouteConfiguration(method: .get,
                                        path: .path([city.thumb ?? ""]),
                                        mockFilePath:
                                            .path(["Cities", "Thumbs", String(format: "%i.jpg", city.cityID)]))
        case .image(let city):
            return TNRouteConfiguration(method: .get,
                                        path: .path([city.image ?? ""]),
                                        mockFilePath:
                                            .path(["Cities", "Images", String(format: "%i.jpg", city.cityID)]))
        }
    }
}
