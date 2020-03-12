//
//  TestTNRequest.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import TermiNetwork

class TestTNRequest: XCTestCase {
    lazy var router: TNRouter<APIRouter> = {
       return TNRouter<APIRouter>()
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

        router.start(APIRouter.testHeaders,
                     responseType: TestHeaders.self,
                     onSuccess: { object in
            failed = !(object.authorization == "XKJajkBXAUIbakbxjkasbxjkas" && object.customHeader == "test!!!!")
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testGetParams() {
        let expectation = XCTestExpectation(description: "Test get params")
        var failed = true

        router.start(APIRouter.testGetParams(value1: true,
                                             value2: 3,
                                             value3: 5.13453124189,
                                             value4: "test",
                                             value5: nil), responseType: TestParam.self, onSuccess: { object in
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testGetParamsEscaped() {
        let expectation = XCTestExpectation(description: "Test get params")
        var failed = true

        router.start(APIRouter.testGetParams(value1: true,
                                             value2: 3,
                                             value3: 5.13453124189,
                                             value4: "τεστ",
                                             value5: nil),
                     responseType: TestParam.self,
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testPostParams() {
        let expectation = XCTestExpectation(description: "Test post params")
        var failed = true

        router.start(APIRouter.testPostParamsxWWWFormURLEncoded(value1: true,
                                                                value2: 3,
                                                                value3: 5.13453124189,
                                                                value4: "test",
                                                                value5: nil), responseType: TestParam.self,
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testJSONRequestPostParams() {
        let expectation = XCTestExpectation(description: "Test JSON post params")
        var failed = true

        router.start(APIRouter.testPostParams(value1: true,
                                              value2: 3,
                                              value3: 5.13453124189,
                                              value4: "test",
                                              value5: nil), responseType: TestJSONParams.self, onSuccess: { object in
            failed = !(object.param1 == true &&
                object.param2 == 3 &&
                object.param3 == 5.13453124189 &&
                object.param4 == "test" &&
                    object.param5 == nil)
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10)

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

        wait(for: [expectation], timeout: 10)

        XCTAssert(queue.operationCount == 3)
    }

    func testAfterAllRequests() {
        let expectation = XCTestExpectation(description: "Test testAfterAllRequests")
        let queue = TNQueue()

        queue.afterAllRequestsCallback = { error in
            expectation.fulfill()
        }

        sampleRequest(queue: queue)
        sampleRequest(queue: queue)
        sampleRequest(queue: queue)

        wait(for: [expectation], timeout: 60)

        XCTAssert(true)
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

        wait(for: [expectation], timeout: 10)
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

        wait(for: [expectation], timeout: 10)
        XCTAssert(!failed)
    }

    func testStringResponse() {
        let expectation = XCTestExpectation(description: "Test afterEachRequestCallback")
        var failed = true
        TNQueue.shared.cancelAllOperations()

        let request = TNRequest(route: APIRouter.testPostParams(value1: true,
                                                                value2: 3,
                                                                value3: 5.13453124189,
                                                                value4: "test",
                                                                value5: nil))
        request.requestBodyType = .JSON
        request.start(responseType: String.self, onSuccess: { _ in
            failed = false
            expectation.fulfill()
        }, onFailure: nil)

        wait(for: [expectation], timeout: 10)
        XCTAssert(!failed)
    }

    func testConfiguration() {
        var request = TNRequest(route: APIRouter.testInvalidParams(value1: "a", value2: "b"))
        var urlRequest = try? request.asRequest()
        XCTAssert(urlRequest?.timeoutInterval == 60)
        XCTAssert(request.cachePolicy == .useProtocolCachePolicy)
        XCTAssert(request.requestBodyType == .xWWWFormURLEncoded)

        TNEnvironment.set(Environment.termiNetworkLocal)
        request = TNRequest(route: APIRouter.testConfiguration)
        urlRequest = try? request.asRequest()
        XCTAssert(urlRequest?.timeoutInterval == 32)
        XCTAssert(request.cachePolicy == .returnCacheDataElseLoad)
        XCTAssert(request.requestBodyType == .JSON)

        TNEnvironment.set(Environment.termiNetworkRemote)
        request = TNRequest(route: APIRouter.testConfiguration)
        urlRequest = try? request.asRequest()
        XCTAssert(urlRequest?.timeoutInterval == 12)
        XCTAssert(request.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
        XCTAssert(request.requestBodyType == .JSON)
    }

    func sampleRequest(queue: TNQueue? = TNQueue.shared, onSuccess: TNSuccessCallback<TestJSONParams>? = nil) {
        let call = TNRequest(route: APIRouter.testPostParams(value1: true,
                                                             value2: 3,
                                                             value3: 5.13453124189,
                                                             value4: "test",
                                                             value5: nil))
        call.requestBodyType = .JSON

        call.start(queue: queue, responseType: TestJSONParams.self, onSuccess: onSuccess, onFailure: nil)
    }
}
