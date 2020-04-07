//
//  TestHeader.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

struct TestHeaders: Codable {

    let authorization: String?
    let customHeader: String?

    enum CodingKeys: String, CodingKey {
        case authorization = "HTTP_AUTHORIZATION"
        case customHeader = "HTTP_CUSTOM_HEADER"
    }
}
