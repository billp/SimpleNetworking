// TestMockRequests.swift
//
// Copyright © 2018-2020 Vasilis Panagiotopoulos. All rights reserved.
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import XCTest
import TermiNetwork

class TestMockRequests: XCTestCase {
    static var envConfiguration: TNConfiguration = {
        let conf = TNConfiguration()
        conf.verbose = true
        conf.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        conf.timeoutInterval = 111
        conf.requestBodyType = .JSON
        conf.headers = ["test": "123", "test2": "abcdefg"]
        conf.verbose = true

        if let bundlePath = Bundle(for: TestTNConfiguration.self).path(forResource: "MockData", ofType: "bundle") {
            conf.mockDataBundle = Bundle(path: bundlePath)
            conf.mockDataEnabled = true
        }

        return conf
    }()

    static var mockDelayConfiguration: TNConfiguration = {
        let conf = TNConfiguration()
        conf.verbose = true
        conf.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        conf.timeoutInterval = 111
        conf.requestBodyType = .JSON
        conf.headers = ["test": "123", "test2": "abcdefg"]
        conf.verbose = true

        if let bundlePath = Bundle(for: TestTNConfiguration.self).path(forResource: "MockData", ofType: "bundle") {
            conf.mockDataBundle = Bundle(path: bundlePath)
            conf.mockDataEnabled = true
            conf.mockDelay = TNMockDelayType(min: 0.3, max: 2.05)
        }

        return conf
    }()

    enum Env: TNEnvironmentProtocol {
        case test

        func configure() -> TNEnvironment {
            switch self {
            case .test:
                return TNEnvironment(scheme: .https,
                                     host: "terminetwork-rails-app.herokuapp.com",
                                     configuration: envConfiguration)
            }
        }
    }

    var router: TNRouter<APIRoute> {
       return TNRouter<APIRoute>()
    }

    var router2: TNRouter<APIRoute> {
        return TNRouter<APIRoute>(configuration: TestMockRequests.mockDelayConfiguration)
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TNEnvironment.set(Env.test)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnvConfiguration() {
        let expectation = XCTestExpectation(description: "testEnvConfiguration")
        var failed = true

        router.request(for: .testHeaders).start(responseType: TestHeaders.self,
                                                onSuccess: { response in
                                                    failed = !(response.customHeader == "yo man!!!!")
                                                    expectation.fulfill()
                                                }, onFailure: nil)

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)

    }

    func testMockDelay() {
        let expectation = XCTestExpectation(description: "testMockDelay")
        var failed = true
        let now = Date().timeIntervalSince1970
        router2.request(for: .testHeaders).start(responseType: TestHeaders.self,
                                                 onSuccess: { response in
                                                        let res = now.distance(to: Date().timeIntervalSince1970)
                                                        let timeCheck = res >= TestMockRequests
                                                            .mockDelayConfiguration.mockDelay!.min
                                                            && res <= TestMockRequests
                                                                .mockDelayConfiguration.mockDelay!.max
                                                    failed = !(response.customHeader == "yo man!!!!" && timeCheck)
                                                        expectation.fulfill()
                                                    }, onFailure: nil)

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)

    }
}
