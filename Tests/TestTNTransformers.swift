// TestTNTransformers.swift
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
        let expectation = XCTestExpectation(description: "testGetParamsWithTransformer")
        var failed = true
        var testModel: TestModel?
        router.request(for: .testGetParams(value1: true,
                                           value2: 3,
                                           value3: 5.13453124189,
                                           value4: "test",
                                           value5: nil)).start(transformer: TestTransformer.self,
                                                               onSuccess: { object in
            testModel = object
            failed = false
            expectation.fulfill()
        }, onFailure: { _, _ in
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed && testModel?.name == "true")
    }

}
