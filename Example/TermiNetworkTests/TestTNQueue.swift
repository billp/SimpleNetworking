//
//  TestTNQueue.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 30/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import TermiNetwork

class TestTNQueue: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testQueue() {
        var numberOfRequests = 8
        let queue = TNQueue()
        let expectation = XCTestExpectation(description: "Test queue")

        queue.afterAllRequestsCallback = { error in
            expectation.fulfill()
        }

        for _ in 1...numberOfRequests {
            TNRequest(method: .get,
                      url: "http://google.com",
                      headers: nil,
                      params: nil).start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in
                numberOfRequests -= 1
            })
        }

        wait(for: [expectation], timeout: 60)

        XCTAssert(numberOfRequests == 0)
    }

    func testQueueCompletionBlockWithoutErrorContinue() {
        let queue = TNQueue(failureMode: .continue)
        let expectation = XCTestExpectation(description: "testQueueCompletionBlock")
        var completedWithError = false
        let urls = ["http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com"]
        var numberOfRequests = urls.count

        queue.afterAllRequestsCallback = { error in
            completedWithError = error
            expectation.fulfill()
        }

        for index in 0...numberOfRequests-1 {
            TNRequest(method: .get,
                      url: urls[index],
                      headers: nil,
                      params: nil).start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in
                numberOfRequests -= 1
            })
        }

        wait(for: [expectation], timeout: 10)

        XCTAssert(queue.operationCount == 0 && !completedWithError)
    }

    func testQueueCompletionBlockWithoutErrorCancelAll() {
        let queue = TNQueue(failureMode: .cancelAll)
        let expectation = XCTestExpectation(description: "testQueueCompletionBlock")
        var completedWithError = false
        let urls = ["http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com"]
        var numberOfRequests = urls.count

        queue.afterAllRequestsCallback = { error in
            completedWithError = error
            expectation.fulfill()
        }

        for index in 0...numberOfRequests-1 {
            TNRequest(method: .get,
                      url: urls[index],
                      headers: nil,
                      params: nil).start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in
                numberOfRequests -= 1
            })
        }

        wait(for: [expectation], timeout: 60)

        XCTAssert(queue.operationCount == 0 && !completedWithError)
    }

    func testQueueCompletionBlockWithErrorContinue() {
        let queue = TNQueue(failureMode: .continue)
        let expectation = XCTestExpectation(description: "testQueueCompletionBlock")
        let urls = ["http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://localhost:3213213",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com"]
        var numberOfRequests = urls.count
        var completedWithError = false

        queue.afterAllRequestsCallback = { error in
            completedWithError = error
            expectation.fulfill()
        }

        for index in 0...numberOfRequests-1 {
            TNRequest(method: .get,
                      url: urls[index],
                      headers: nil,
                      params: nil).start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in
                numberOfRequests -= 1
            })
        }

        wait(for: [expectation], timeout: 10)
        XCTAssert(queue.operationCount == 0 && completedWithError)
    }

    func testQueueCompletionBlockWithErrorCancelAll() {
        let queue = TNQueue(failureMode: .cancelAll)
        let expectation = XCTestExpectation(description: "testQueueCompletionBlock")
        let urls = ["http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com",
                    "http://localhost:3213213",
                    "http://google.com",
                    "http://google.com",
                    "http://google.com"]
        var numberOfRequests = urls.count
        var completedWithError = false

        queue.afterAllRequestsCallback = { error in
            completedWithError = error
            expectation.fulfill()
        }

        for index in 0...numberOfRequests-1 {
            TNRequest(method: .get,
                      url: urls[index],
                      headers: nil,
                      params: nil).start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in })
        }

        wait(for: [expectation], timeout: 10)
        XCTAssert(queue.operationCount == 0 && completedWithError)
    }

    func testQueueCancellation() {
        var numberOfRequests = 8
        let queue = TNQueue()
        let expectation = XCTestExpectation(description: "testQueueCancellation")

        queue.afterAllRequestsCallback = { error in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                expectation.fulfill()
            })
        }

        for _ in 1...numberOfRequests {
            TNRequest(method: .get,
                      url: "http://google.com",
                      headers: nil,
                      params: nil).start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in
                numberOfRequests -= 1
            })
        }

        queue.cancelAllOperations()

        wait(for: [expectation], timeout: 20)

        XCTAssert(queue.operationCount == 0)
    }

    func testQueueFailureModeCancelAll() {
        var numberOfRequests = 8
        let queue = TNQueue(failureMode: .cancelAll)
        let expectation = XCTestExpectation(description: "testQueueFailureModeCancelAll")

        queue.maxConcurrentOperationCount = 1

        for index in 1...8 {
            let url = index == 5 ? "http://localhost.unkownhost" : "http://google.com"

            let call = TNRequest(method: .get, url: url, headers: nil, params: nil)

            call.start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { error, _ in

                if case .cancelled(_) = error {

                } else {
                    numberOfRequests -= 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    expectation.fulfill()
                })
            })
        }

        wait(for: [expectation], timeout: 20)

        XCTAssert(queue.operationCount == 0 && numberOfRequests == 3)
    }

    func testQueueFailureModeContinue() {
        var numberOfRequests = 8
        let queue = TNQueue(failureMode: .cancelAll)
        let expectation = XCTestExpectation(description: "testQueueFailureModeContinue")
        queue.maxConcurrentOperationCount = 1

        queue.afterAllRequestsCallback = { error in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                expectation.fulfill()
            })
        }

        for index in 1...8 {
            let url = index == 1 ? "http://localhost.unkownhost" : "http://google.com"

            let call = TNRequest(method: .get, url: url, headers: nil, params: nil)

            call.start(queue: queue, responseType: Data.self, onSuccess: { _ in
                numberOfRequests -= 1
            }, onFailure: { _, _ in

            })
        }

        wait(for: [expectation], timeout: 60)

        XCTAssert(queue.operationCount == 0)
    }
}
