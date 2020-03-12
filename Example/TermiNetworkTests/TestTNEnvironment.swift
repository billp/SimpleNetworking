//
//  TermiNetworkTests.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 27/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import TermiNetwork

class TestTNEnvironment: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnvironments() {
        TNEnvironment.set(Environment.httpHost)
        XCTAssert(TNEnvironment.current.description == "http://localhost")

        TNEnvironment.set(Environment.httpHostWithPort)
        XCTAssert(TNEnvironment.current.description == "http://localhost:8080")

        TNEnvironment.set(Environment.httpHostWithPortAndSuffix)
        XCTAssert(TNEnvironment.current.description == "http://localhost:8080/v1/json")

        TNEnvironment.set(Environment.httpsHostWithPortAndSuffix)
        XCTAssert(TNEnvironment.current.description == "https://google.com:8080/v3/test/foo/bar")
    }
}
