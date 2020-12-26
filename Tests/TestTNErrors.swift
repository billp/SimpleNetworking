// TestTNErrors.swift
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

class TestTNErrors: XCTestCase {
    var router: Router<APIRoute> {
       return Router<APIRoute>()
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Environment.set(Env.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        Environment.set(Env.termiNetworkRemote)
    }

    func testEnvironmenotSetFullUrl() {
        Environment.current = nil
        let expectation = XCTestExpectation(description: "testEnvironmenotSetFullUrl")
        var failed = true

        Request(method: .get,
                  url: "http://www.google.com",
                  headers: nil,
                  params: nil).start(responseType: Data.self, onSuccess: { _ in
                    failed = false
                    expectation.fulfill()
                  }, onFailure: { error, _ in
                    if case TNError.environmenotSet = error {
                        failed = true
                    } else {
                        failed = false
                    }
                    expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testEnvironmenotSetWithRoute() {
        Environment.current = nil
        let expectation = XCTestExpectation(description: "testEnvironmenotSetWithRoute")
        var failed = true

        router.request(for: .testPostParams(value1: true,
                                            value2: 1,
                                            value3: 2,
                                            value4: "Dsa",
                                            value5: "A"))
                    .start(responseType: Data.self,
                           onSuccess: { _ in
                                expectation.fulfill()
                    }, onFailure: { error, _ in
                        if case TNError.environmenotSet = error {
                            failed = false
                        }
                        expectation.fulfill()
                    })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testInvalidURL() {
        do {
            try _ = Request(method: .get, url: "http://εεε.google.κωμ", headers: nil, params: nil).asRequest()
            XCTAssert(false)
        } catch TNError.invalidURL {
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }

    func testValidURL() {
        do {
            try _ = Request(method: .get, url: "http://www.google.com", headers: nil, params: nil).asRequest()
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }

    func testResponseDataIsNotEmpty() {
        let expectation = XCTestExpectation(description: "testResponseDataIsNotEmpty")
        var failed = true

        router.request(for: .testEmptyBody).start(responseType: Data.self,
                                                    onSuccess: { _ in
                                                        expectation.fulfill()
                                                        failed = false
                                                    }, onFailure: { _, _ in
                                                        expectation.fulfill()
                                                        failed = true
                                                    }).start()

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testResponseInvalidImageData() {
        let expectation = XCTestExpectation(description: "testResponseInvalidImageData")
        var failed = true

        router.request(for: .testPostParams(value1: false,
                                            value2: 1,
                                            value3: 2,
                                            value4: "",
                                            value5: nil)).start(responseType: UIImage.self,
                                                                onSuccess: { _ in
            failed = true
            expectation.fulfill()
        }, onFailure: { error, _ in
            switch error {
            case .responseInvalidImageData:
                failed = false
            default:
                failed = true
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testResponseValidImageData() {
        let expectation = XCTestExpectation(description: "testResponseValidImageData")
        var failed = true

        router.request(for: .testImage(imageName: "sample.jpeg")).start(responseType: UIImage.self,
                                                                        onSuccess: { _ in
            expectation.fulfill()
            failed = false
        }, onFailure: { _, _ in
            expectation.fulfill()
            failed = true
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testResponseCannotDeserialize() {
        let expectation = XCTestExpectation(description: "testResponseCannotDeserialize")
        var failed = true

        router.request(for: .testInvalidParams(value1: "a", value2: "b")).start(responseType: TestParams.self,
                                                                                onSuccess: { _ in
            failed = true
            expectation.fulfill()
        }, onFailure: { error, _ in
            switch error {
            case .cannotDeserialize:
                failed = false
            default:
                debugPrint("failed with: " + error.localizedDescription)
                failed = true
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testResponseCanDeserialize() {
        let expectation = XCTestExpectation(description: "testResponseCanDeserialize")
        var failed = true

        router.request(for: .testGetParams(value1: false,
                                           value2: 3,
                                           value3: 1.32,
                                           value4: "Test",
                                           value5: nil)).start(responseType: TestParams.self, onSuccess: { _ in
            failed = false
            expectation.fulfill()
        }, onFailure: { error, _ in
            debugPrint("failed with: " + error.localizedDescription)
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func tesetworkError() {
        Environment.set(Env.invalidHost)

        let expectation = XCTestExpectation(description: "tesetworkError")
        var failed = true

        router.request(for: .testInvalidParams(value1: "a", value2: "b")).start(responseType: Data.self,
                                                                                onSuccess: { _ in
            failed = true
            expectation.fulfill()
        }, onFailure: { error, _ in
            switch error {
            case .networkError:
                failed = false
            default:
                debugPrint("failed with: " + error.localizedDescription)
                failed = true
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func tesotSuccess() {
        let expectation = XCTestExpectation(description: "tesotSuccess")
        var failed = true

        router.request(for: .testStatusCode(code: 404))
            .start(responseType: String.self,
                        onSuccess: { _ in
                                    expectation.fulfill()
                                    failed = true

                        }, onFailure: { error, _ in
                                    switch error {
                                    case .notSuccess(let code):
                                        failed = code != 404
                                    default:
                                        failed = true
                        }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testCancelled() {
        let expectation = XCTestExpectation(description: "testCancelled")
        var failed = true

        let request = Request(route: APIRoute.testStatusCode(code: 404))
        request.start(responseType: Data.self, onSuccess: { _ in
            expectation.fulfill()
        }, onFailure: { error, _ in
            switch error {
            case .cancelled:
                failed = false
            default:
                failed = true
            }
            expectation.fulfill()
        })

        request.cancel()

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }
}
