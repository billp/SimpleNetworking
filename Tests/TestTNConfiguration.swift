// TNQueue.swift
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
// swiftlint:disable discouraged_direct_init

import XCTest
import TermiNetwork

class TestTNConfiguration: XCTestCase {
    static var envConfiguration: TNRequestConfiguration = {
        let conf = TNRequestConfiguration()
        conf.verbose = true
        conf.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        conf.timeoutInterval = 111
        conf.requestBodyType = .JSON
        conf.certificateData = "test".data(using: .utf8) as NSData?
        conf.bundle = Bundle()
        conf.headers = ["test": "123", "test2": "abcdefg"]

        return conf
    }()

    static var routeConfiguration: TNRequestConfiguration = {
        let conf = TNRequestConfiguration()
        conf.verbose = false
        conf.cachePolicy = .returnCacheDataDontLoad
        conf.timeoutInterval = 231
        conf.requestBodyType = .xWWWFormURLEncoded
        conf.certificateData = "hi".data(using: .utf8) as NSData?
        conf.bundle = Bundle()
        conf.headers = ["test": "test", "afb": "fff"]

        return conf
    }()

    enum Env: TNEnvironmentProtocol {
        case test

        func configure() -> TNEnvironment {
            switch self {
            case .test:
                return TNEnvironment(scheme: .http,
                                     host: "google.com",
                                     configuration: TestTNConfiguration.envConfiguration)
            }
        }
    }

    var router: TNRouter<APIRouter> {
       return TNRouter<APIRouter>()
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
        let request = router.request(forRoute: .testHeaders)
        let reqConf = request.configuration
        let envConf = request.configuration

        XCTAssert(reqConf.verbose == envConf.verbose)
        XCTAssert(reqConf.cachePolicy == envConf.cachePolicy)
        XCTAssert(reqConf.timeoutInterval == envConf.timeoutInterval)
        XCTAssert(reqConf.requestBodyType == envConf.requestBodyType)
        XCTAssert(reqConf.certificateData == envConf.certificateData)
        XCTAssert(reqConf.bundle == envConf.bundle)
        XCTAssert(reqConf.verbose == envConf.verbose)
        XCTAssert(reqConf.headers == envConf.headers)
    }

    func testRouteConfiguration() {
        let request = router.request(forRoute:
            .testConfigurationParameterized(conf: TestTNConfiguration.routeConfiguration))
        let reqConf = request.configuration
        let routeConf = TestTNConfiguration.routeConfiguration

        var allHeaders = TestTNConfiguration.envConfiguration.headers

        allHeaders.merge(routeConf.headers, uniquingKeysWith: { _, new in new})

        XCTAssert(reqConf.verbose == routeConf.verbose)
        XCTAssert(reqConf.cachePolicy == routeConf.cachePolicy)
        XCTAssert(reqConf.timeoutInterval == routeConf.timeoutInterval)
        XCTAssert(reqConf.requestBodyType == routeConf.requestBodyType)
        XCTAssert(reqConf.certificateData == routeConf.certificateData)
        XCTAssert(reqConf.bundle == routeConf.bundle)
        XCTAssert(reqConf.verbose == routeConf.verbose)
        XCTAssert(reqConf.headers == allHeaders)
    }
}
