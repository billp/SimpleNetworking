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

import XCTest
import TermiNetwork

class TestExtensions: XCTestCase {
    lazy var sampleImageURL = TNEnvironment.current.description + "/sample.jpeg"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testImageViewRemoteURL() {
        let expectation = XCTestExpectation(description: "Test testImageViewRemoteURL")
        var failed = true
        var tmp = 0

        let imageView = UIImageView()
        try? imageView.tn_setRemoteImage(url: sampleImageURL,
                                         defaultImage: nil,
                                         beforeStart: {
            tmp += 1
        }, preprocessImage: { image in
            tmp += 1
            if tmp != 2 {
                failed = true
                expectation.fulfill()
            }
            return image
        }, onFinish: { image, error in
            failed = !(tmp == 2 && image != nil && error == nil)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)
        XCTAssert(!failed)
    }
}
