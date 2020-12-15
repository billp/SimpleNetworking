// TestTNEnvironment.swift
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

class TestTNEnvironment: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnvironments() {
        TNEnvironment.set(Environment.httpHost)
        XCTAssert(TNEnvironment.current.stringUrl == "http://localhost")

        TNEnvironment.set(Environment.httpHostWithPort)
        XCTAssert(TNEnvironment.current.stringUrl == "http://localhost:8080")

        TNEnvironment.set(TNEnvironment(url: "http://www.google.com:8009/test/2"))
        XCTAssert(TNEnvironment.current.stringUrl == "http://www.google.com:8009/test/2")

        TNEnvironment.set(Environment.httpHostWithPortAndSuffix)
        XCTAssert(TNEnvironment.current.stringUrl == "http://localhost:8080/v1/json")

        TNEnvironment.set(Environment.httpsHostWithPortAndSuffix)
        XCTAssert(TNEnvironment.current.stringUrl == "https://google.com:8080/v3/test/foo/bar")
    }
}
