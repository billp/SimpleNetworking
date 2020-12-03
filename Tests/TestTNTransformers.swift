//
//  TestTNTransformers.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 3/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import XCTest
import TermiNetwork

class TestTNTransformers: XCTestCase {
    lazy var router: TNRouter<APIRoute> = {
        return TNRouter<APIRoute>(configuration: TNConfiguration(verbose: true))
    }()

    override class func setUp() {
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    func testGetParamsWithTransformer() {
        let expectation = XCTestExpectation(description: "Test get params")
        var failed = true
        var newModel: TestModel?
        router.request(for: .testGetParams(value1: true,
                                           value2: 3,
                                           value3: 5.13453124189,
                                           value4: "test",
                                           value5: nil)).start(responseType: TestParams.self, onSuccess: { object in
            newModel = object.transform(from: TestParams.self,
                                        to: TestModel.self,
                                        transformer: TestTransformer())
            failed = false
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed && newModel?.name == "true")
    }

}
