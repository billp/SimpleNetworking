//
//  CitiesTransformer.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 4/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

final class CitiesTransformer: TNTransformer<[RSCity], [City]> {
    override func transform(_ object: [RSCity]) throws -> [City] {
        object.map { rsCity in
            City(id: UUID(),
                 cityID: rsCity.id,
                 name: rsCity.name,
                 description: rsCity.description,
                 countryName: rsCity.countryName,
                 thumb: rsCity.thumb,
                 image: rsCity.image)
        }
    }
}
