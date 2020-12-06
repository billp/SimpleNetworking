//
//  CityTransformer.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 6/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import TermiNetwork

class CityTransformer: TNTransformer<RSCity, City> {
    override func transform(_ object: RSCity) throws -> City {
        City(id: UUID(),
             cityID: object.id,
             name: object.name,
             description: object.description,
             countryName: object.countryName,
             thumb: object.thumb,
             image: object.image)
    }
}
