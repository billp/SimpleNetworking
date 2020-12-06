// TNRequest.swift
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

// swiftlint:disable type_body_length

class TestTNRequest: XCTestCase {
    lazy var router: TNRouter<APIRoute> = {
        return TNRouter<APIRoute>(configuration: TNConfiguration(verbose: true))
    }()

    lazy var router2: TNRouter<APIRoute> = {
        return TNRouter<APIRoute>(environment: Environment.google)
    }()

    lazy var routerWithMiddleware: TNRouter<APIRoute> = {
        let configuration = TNConfiguration()
        configuration.requestMiddlewares = [CryptoMiddleware()]
        configuration.verbose = true
        configuration.requestBodyType = .JSON

        let router = TNRouter<APIRoute>(environment: Environment.termiNetworkRemote,
                                        configuration: configuration)

        return router
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHeaders() {
        let expectation = XCTestExpectation(description: "Test headers")
        var failed = true

        router.request(for: .testHeaders)
                     .start(responseType: TestHeaders.self,
                            onSuccess: { object in
            failed = !(object.authorization == "XKJajkBXAUIbakbxjkasbxjkas" && object.customHeader == "test!!!!")
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testOverrideHeaders() {
        let expectation = XCTestExpectation(description: "Test headers")
        var failed = true

        router.request(for: .testOverrideHeaders)
                    .start(responseType: TestHeaders.self,
                     onSuccess: { object in
            failed = !(object.authorization == "0" &&
                        object.customHeader == "0" &&
                         object.userAgent == "ios")
            expectation.fulfill()
        }, onFailure: { (_, _) in
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testGetParams() {
        let expectation = XCTestExpectation(description: "Test get params")
        var failed = true

        router.request(for: .testGetParams(value1: true,
                                           value2: 3,
                                           value3: 5.13453124189,
                                           value4: "test",
                                           value5: nil)).start(responseType: TestParams.self, onSuccess: { object in
            failed = !(object.param1 == "true" &&
                object.param2 == "3" &&
                object.param3 == "5.13453124189" &&
                object.param4 == "test" &&
                object.param5 == nil)
            failed = false
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testGetParamsEscaped() {
        let expectation = XCTestExpectation(description: "Test get params")
        var failed = true

        router.request(for: .testGetParams(value1: true,
                                           value2: 3,
                                           value3: 5.13453124189,
                                           value4: "τεστ",
                                           value5: nil))
            .start(responseType: TestParams.self,
                   onSuccess: { object in
            failed = !(object.param1 == "true" &&
                object.param2 == "3" &&
                object.param3 == "5.13453124189" &&
                object.param4 == "τεστ" &&
                object.param5 == nil)
            failed = false
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testPostParams() {
        let expectation = XCTestExpectation(description: "Test post params")
        var failed = true

        router.request(for: .testPostParamsxWWWFormURLEncoded(value1: true,
                                                              value2: 3,
                                                              value3: 5.13453124189,
                                                              value4: "test",
                                                              value5: nil))
            .start(responseType: TestParams.self,
                   onSuccess: { object in
            failed = !(object.param1 == "true" &&
                object.param2 == "3" &&
                object.param3 == "5.13453124189" &&
                object.param4 == "test" &&
                object.param5 == nil)
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testJSONRequestPostParams() {
        let expectation = XCTestExpectation(description: "Test JSON post params")
        var failed = true

        router.request(for: .testPostParams(value1: true,
                                            value2: 3,
                                            value3: 5.13453124189,
                                            value4: "test",
                                            value5: nil)).start(responseType: TestJSONParams.self,
                                                                onSuccess: { object in
            failed = !(object.param1 == true &&
                object.param2 == 3 &&
                object.param3 == 5.13453124189 &&
                object.param4 == "test" &&
                    object.param5 == nil)
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testBeforeAllRequests() {
        let expectation = XCTestExpectation(description: "Test beforeEachRequestCallback")
        let queue = TNQueue()
        queue.beforeAllRequestsCallback = {
            expectation.fulfill()
        }

        self.sampleRequest(queue: queue)
        self.sampleRequest(queue: queue)
        self.sampleRequest(queue: queue)

        wait(for: [expectation], timeout: 60)

        XCTAssert(queue.operationCount == 3)
    }

    func testAfterAllRequests() {
        let expectation = XCTestExpectation(description: "Test testAfterAllRequests")
        let queue = TNQueue()
        var failed = true

        queue.afterAllRequestsCallback = { error in
            failed = queue.operations.count > 0
            expectation.fulfill()
        }

        sampleRequest(queue: queue)
        sampleRequest(queue: queue)
        sampleRequest(queue: queue)

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testBeforeEachRequest() {
        let expectation = XCTestExpectation(description: "Test beforeEachRequestCallback")
        var failed = true
        let queue = TNQueue()

        queue.beforeEachRequestCallback = { _ in
            expectation.fulfill()
            failed = false
        }

        sampleRequest(queue: queue)

        wait(for: [expectation], timeout: 60)
        XCTAssert(!failed)
    }

    func testAfterEachRequest() {
        let expectation = XCTestExpectation(description: "Test afterEachRequestCallback")
        var failed = true
        TNQueue.shared.cancelAllOperations()

        TNQueue.shared.afterEachRequestCallback = { call, data, URLResponse, error in
            failed = false
            expectation.fulfill()
        }

        sampleRequest(onSuccess: { _ in })

        wait(for: [expectation], timeout: 60)
        XCTAssert(!failed)
    }

    func testStringResponse() {
        let expectation = XCTestExpectation(description: "Test afterEachRequestCallback")
        var failed = true
        TNQueue.shared.cancelAllOperations()

        let request = TNRequest(route: APIRoute.testPostParams(value1: true,
                                                               value2: 3,
                                                               value3: 5.13453124189,
                                                               value4: "test",
                                                               value5: nil))
        request.configuration.requestBodyType = .JSON
        request.start(responseType: String.self, onSuccess: { _ in
            failed = false
            expectation.fulfill()
        }, onFailure: nil)

        wait(for: [expectation], timeout: 60)
        XCTAssert(!failed)
    }

    func testConfiguration() {
        var request = TNRequest(route: APIRoute.testInvalidParams(value1: "a", value2: "b"))
        var urlRequest = try? request.asRequest()
        XCTAssert(urlRequest?.timeoutInterval == 60)
        XCTAssert(request.configuration.cachePolicy == .useProtocolCachePolicy)
        XCTAssert(request.configuration.requestBodyType == .xWWWFormURLEncoded)

        TNEnvironment.set(Environment.termiNetworkLocal)
        request = TNRequest(route: APIRoute.testHeaders)
        urlRequest = try? request.asRequest()
        XCTAssert(urlRequest?.timeoutInterval == 32)
        XCTAssert(request.configuration.cachePolicy == .returnCacheDataElseLoad)
        XCTAssert(request.configuration.requestBodyType == .JSON)

        TNEnvironment.set(Environment.termiNetworkRemote)
        request = TNRequest(route: APIRoute.testConfiguration)
        urlRequest = try? request.asRequest()
        XCTAssert(urlRequest?.timeoutInterval == 12)
        XCTAssert(request.configuration.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
        XCTAssert(request.configuration.requestBodyType == .JSON)
    }

    func testOverrideEnvironment() {
        TNEnvironment.set(Environment.termiNetworkRemote)

        let expectation1 = XCTestExpectation(description: "Test testOverrideEnvironment")
        let expectation2 = XCTestExpectation(description: "Test testOverrideEnvironment")

        var failed = true

        router.request(for: .testGetParams(value1: false,
                                           value2: 2,
                                           value3: 3,
                                           value4: "1",
                                           value5: nil)).start(responseType: Data.self,
        onSuccess: { _ in
            failed = false
            expectation1.fulfill()
        }, onFailure: { (_, _) in
            failed = true
            expectation1.fulfill()
        })

        wait(for: [expectation1], timeout: 60)

        XCTAssert(!failed)

        failed = true

        router2.request(for: .testGetParams(value1: false,
                                            value2: 2,
                                            value3: 3,
                                            value4: "1",
                                            value5: nil))
            .start(responseType: String.self,
                      onSuccess: { _ in
            expectation2.fulfill()
        }, onFailure: { (error, _) in
            if case .notSuccess(404) = error {
                failed = false
            }
            expectation2.fulfill()

            XCTAssert(!failed)
        })

        wait(for: [expectation2], timeout: 60)
    }

    func testMiddleware() {
        var failed = true

        let expectation = XCTestExpectation(description: "Test encrypted request")

        routerWithMiddleware.request(for: .testEncryptParams(value: "Yoooo"))
            .start(responseType: EncryptedModel.self,
                   onSuccess: { model in
                        failed = model.value != "Yoooo"
                        expectation.fulfill()
                   }, onFailure: { (_, _) in
                        failed = true
                        expectation.fulfill()
                   })

        wait(for: [expectation], timeout: 60)
        XCTAssert(!failed)
    }

    fileprivate func sampleRequest(queue: TNQueue? = TNQueue.shared,
                                   onSuccess: TNSuccessCallback<TestJSONParams>? = nil) {
        let call = TNRequest(route: APIRoute.testPostParams(value1: true,
                                                            value2: 3,
                                                            value3: 5.13453124189,
                                                            value4: "test",
                                                            value5: nil))
        call.configuration.requestBodyType = .JSON

        call.start(queue: queue,
                   responseType: TestJSONParams.self,
                   onSuccess: onSuccess, onFailure: nil)
    }
}
