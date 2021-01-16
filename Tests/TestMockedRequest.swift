// TestMockRequests.swift
//
// Copyright © 2018-2021 Vasilis Panagiotopoulos. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import XCTest
import TermiNetwork

class TestMockedRequests: XCTestCase {
    static var envConfiguration: Configuration = {
        let conf = Configuration()
        conf.verbose = true
        conf.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        conf.timeoutInterval = 111
        conf.requestBodyType = .JSON
        conf.headers = ["test": "123", "test2": "abcdefg"]
        conf.verbose = true

        if let bundlePath = Bundle(for: TestConfiguration.self).path(forResource: "MockData", ofType: "bundle") {
            conf.mockDataBundle = Bundle(path: bundlePath)
            conf.mockDataEnabled = true
        }

        return conf
    }()

    static var mockDelayConfiguration: Configuration = {
        let conf = Configuration()
        conf.verbose = true
        conf.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        conf.timeoutInterval = 111
        conf.requestBodyType = .JSON
        conf.headers = ["test": "123", "test2": "abcdefg"]
        conf.verbose = true

        if let bundlePath = Bundle(for: TestConfiguration.self).path(forResource: "MockData", ofType: "bundle") {
            conf.mockDataBundle = Bundle(path: bundlePath)
            conf.mockDataEnabled = true
            conf.mockDelay = MockDelayType(min: 0.3, max: 2.05)
        }

        return conf
    }()

    enum Env: EnvironmentProtocol {
        case test

        func configure() -> Environment {
            switch self {
            case .test:
                return Environment(scheme: .https,
                                     host: "terminetwork-rails-app.herokuapp.com",
                                     configuration: envConfiguration)
            }
        }
    }

    var router: Router<APIRoute> {
       return Router<APIRoute>()
    }

    var router2: Router<APIRoute> {
        return Router<APIRoute>(configuration: TestMockedRequests.mockDelayConfiguration)
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Environment.set(Env.test)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnvConfiguration() {
        let expectation = XCTestExpectation(description: "testEnvConfiguration")
        var failed = true

        router.request(for: .testHeaders)
            .success(responseType: TestHeaders.self) { response in
                failed = !(response.customHeader == "yo man!!!!")
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)

    }

    func testMockDelay() {
        let expectation = XCTestExpectation(description: "testMockDelay")
        var failed = true

        let queue = Queue()
        queue.maxConcurrentOperationCount = 20

        queue.afterAllRequestsCallback = { _ in
            expectation.fulfill()
        }

        for _ in 0..<100 {
            let req = router2.request(for: .testHeaders)
            req.configuration.verbose = false
            req.queue(queue)
               .success(responseType: TestHeaders.self) { response in
                    let res = req.mockDelay ?? 0
                    let timeCheck = res >= TestMockedRequests
                        .mockDelayConfiguration.mockDelay!.min
                        && res <= TestMockedRequests
                            .mockDelayConfiguration.mockDelay!.max
                    failed = failed && !(response.customHeader == "yo man!!!!" && timeCheck)
               }
        }
        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testMockFailed() {
        let expectation = XCTestExpectation(description: "testMockFailed")
        var failed = true

        let req = router2.request(for: .testOverrideHeaders)
        req.configuration.verbose = false
        req.success(responseType: TestHeaders.self) { _ in
            failed = true
            expectation.fulfill()
        }
        .failure { error in
            if case .invalidMockData = error {
                failed = false
            } else {
                failed = true
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }
}
