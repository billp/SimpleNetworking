//
//  City.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 1/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation

struct City: Codable {
    let id: Int
    let name: String
    let countryName: String
    let thumb: String
}

struct Cities: Codable {
    var cities: [City]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cities = try values.decode([City].self, forKey: .cities)
    }
}
