//
//  Router.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import TermiNetwork

// swiftlint:disable function_body_length cyclomatic_complexity

enum APIRouter: TNRouterProtocol {
    // Define your routes
    case testHeaders
    case testOverrideHeaders
    case testGetParams(value1: Bool, value2: Int, value3: Double, value4: String, value5: String?)
    case testPostParams(value1: Bool, value2: Int, value3: Double, value4: String, value5: String?)
    case testPostParamsxWWWFormURLEncoded(value1: Bool, value2: Int, value3: Double, value4: String, value5: String?)
    case testInvalidParams(value1: String, value2: String)
    case testStatusCode(code: Int)
    case testEmptyBody
    case testConfiguration
    case testImage(imageName: String)
    case testPinning(certName: String)

    func testPinningConfiguration(withCertName certName: String) -> TNRequestConfiguration {
        let configuration = TNRequestConfiguration()
        configuration.bundle = Bundle.init(for: TestTNEnvironment.self)
        configuration.setCertificateData(withName: certName)
        configuration.headers = ["Custom-Header": "1"]
        return configuration
    }

    // Set method, path, params, headers for each route
    func configure() -> TNRouteConfiguration {
        switch self {
        case .testHeaders:
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_headers"]),
                headers: ["Authorization": "XKJajkBXAUIbakbxjkasbxjkas", "Custom-Header": "test!!!!"]
            )
        case .testOverrideHeaders:
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_headers"]),
                headers: ["Authorization": "0",
                          "Custom-Header": "0",
                          "User-Agent": "ios"]
            )
        case let .testGetParams(value1, value2, value3, value4, value5):
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_params"]),
                params: ["key1": value1, "key2": value2, "key3": value3, "key4": value4, "key5": value5]
            )
        case let .testPostParamsxWWWFormURLEncoded(value1, value2, value3, value4, value5):
            return TNRouteConfiguration(
                method: .post,
                path: .path(["test_params"]),
                params: ["key1": value1, "key2": value2, "key3": value3, "key4": value4, "key5": value5],
                configuration: TNRequestConfiguration(requestBodyType: .xWWWFormURLEncoded)
            )
        case .testConfiguration:
            return TNRouteConfiguration(
                method: .post,
                path: .path(["test_params"]),
                configuration: TNRequestConfiguration(cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                                             timeoutInterval: 12,
                                                             requestBodyType: .JSON)
            )
        case let .testPostParams(value1, value2, value3, value4, value5):
            return TNRouteConfiguration(
                method: .post,
                path: .path(["test_params"]),
                params: ["key1": value1, "key2": value2, "key3": value3, "key4": value4, "key5": value5],
                configuration: TNRequestConfiguration(requestBodyType: .JSON)
            )
        case let .testInvalidParams(value1, value2):
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_params"]),
                params: ["fff": value1, "aaa": value2]
            )
        case .testStatusCode(let code):
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_status_code"]),
                params: ["status_code": code]
            )
        case .testEmptyBody:
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_empty_response"])
            )
        case .testImage(let imageName):
            return TNRouteConfiguration(
                method: .get,
                path: .path([imageName])
            )
        case .testPinning(let certName):
            return TNRouteConfiguration(
                method: .get,
                path: .path(["test_empty_response"]),
                configuration: testPinningConfiguration(withCertName: certName)
            )
        }
    }
}
