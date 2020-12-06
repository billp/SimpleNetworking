//
//  City.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 4/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation

struct City: Identifiable {
    let id: UUID
    let cityID: Int
    let name: String
    let description: String?
    let countryName: String
    let thumb: String?
    let image: String?
}
