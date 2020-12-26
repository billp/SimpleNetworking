//
//  TestInterceptors.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 25/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import XCTest
import TermiNetwork

class TestInterceptors: XCTestCase {
    lazy var router: Router<APIRoute> = {
        let configuration = Configuration()
        configuration.interceptors = [GlobalInterceptor.self]
        configuration.verbose = true
        return Router<APIRoute>(configuration: configuration)
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Environment.set(Env.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInterceptorContinue() {
        Environment.set(Env.termiNetworkRemote)

        let expectation = XCTestExpectation(description: "testInterceptorContinue")
        var failed = true

        router.request(for: .testPostParams(value1: false,
                                            value2: 1,
                                            value3: 2,
                                            value4: "",
                                            value5: nil)).start(responseType: TestJSONParams.self,
                                                                onSuccess: { response in
            failed = !(response.param3 == 2)
            expectation.fulfill()
        }, onFailure: { _, _ in
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testInterceptorRetry() {
        Environment.set(Env.invalidHost)

        let expectation = XCTestExpectation(description: "testInterceptorRetry")
        var failed = true

        router.request(for: .testPostParams(value1: false,
                                            value2: 1,
                                            value3: 2,
                                            value4: "",
                                            value5: nil)).start(responseType: TestJSONParams.self,
                                                                onSuccess: { response in
            failed = !(response.param3 == 2)
            expectation.fulfill()
        }, onFailure: { error, _ in
            print(error)
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }
}
