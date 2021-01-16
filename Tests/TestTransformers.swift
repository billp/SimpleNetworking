// TestTransformers.swift
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

class TestTransformers: XCTestCase {
    lazy var router: Router<APIRoute> = {
        return Router<APIRoute>(configuration: Configuration(verbose: true))
    }()

    override class func setUp() {
        Environment.set(Env.termiNetworkRemote)
    }

    func testCannotTransform() {
        var failed = true
        let object = TestHeaders(authorization: "", customHeader: "", userAgent: "")
        do {
            _ = try object.transform(with: StatusCodeTransformer.init())
        } catch let error {
            if let tnError = error as? TNError {
                if case .transformationFailed = tnError {
                    failed = false
                }
            }
        }

        XCTAssert(!failed)
    }

    func testGetParamsWithTransformerSuccess() {
        let expectation = XCTestExpectation(description: "testGetParamsWithTransformerSuccess")
        var failed = true
        var testModel: TestModel?
        router.request(for: .testGetParams(value1: true,
                                           value2: 3,
                                           value3: 5.13453124189,
                                           value4: "test",
                                           value5: nil))
            .success(transformer: TestTransformer.self) { object in
                testModel = object
                failed = false
                expectation.fulfill()
            }
            .failure { _ in
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed && testModel?.value == "true")
    }

    func testGetParamsWithTransformerSuccessCannotDeserialize() {
        let expectation = XCTestExpectation(description: "testGetParamsWithTransformerSuccessCannotDeserialize")
        var failed = true

        let req = router.request(for: .testGetParams(value1: true,
                                                     value2: 3,
                                                     value3: 5.13453124189,
                                                     value4: "test",
                                                     value5: nil))

        req.success(transformer: StatusCodeTransformer.self) { _ in
               expectation.fulfill()
           }
           .failure { error in
                if case .cannotDeserialize = error {
                    failed = false
                } else {
                    failed = true
                }
                expectation.fulfill()
           }

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testGetParamsWithTransformerSuccessTransformError() {
        let expectation = XCTestExpectation(description: "testGetParamsWithTransformerSuccessTransformError")
        var failed = true

        let req = router.request(for: .testGetParams(value1: true,
                                                     value2: 3,
                                                     value3: 5.13453124189,
                                                     value4: "test",
                                                     value5: nil))

        req.success(transformer: StatusCodeTransformer.self) { _ in
               expectation.fulfill()
           }
           .failure { error in
                if case .cannotDeserialize = error {
                    failed = false
                } else {
                    failed = true
                }
                expectation.fulfill()
           }

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }


    func testGetParamsWithTransformerFailure() {
        let expectation = XCTestExpectation(description: "testGetParamsWithTransformer")
        var failed = true

        let req = router.request(for: .testGetParams(value1: true,
                                                     value2: 3,
                                                     value3: 5.13453124189,
                                                     value4: "test",
                                                     value5: nil))

        req.success(transformer: TestTransformer.self) { _ in
                expectation.fulfill()
           }
           .failure { _ in
                failed = false
                expectation.fulfill()
            }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            req.cancel()
        }

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

}
