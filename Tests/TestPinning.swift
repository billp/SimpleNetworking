// TestPinning.swift
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

class TestPinning: XCTestCase {

    var bundle: Bundle = {
        return Bundle(for: TestPinning.self)
    }()

    var invalidCertPath: String {
        return bundle.path(forResource: "forums.swift.org",
                           ofType: "cer",
                           inDirectory: nil,
                           forLocalization: nil) ?? ""
    }

    var validCertPath: String {
        return bundle.path(forResource: "herokuapp.com",
                           ofType: "cer",
                           inDirectory: nil,
                           forLocalization: nil) ?? ""
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

     func testValidCertificate() {
           let expectation = XCTestExpectation(description: "testValidCertificate")
           var failed = true

            let request = TNRequest(route: APIRoute.testPinning(certPath: validCertPath))
           request.start(responseType: String.self, onSuccess: { _ in
               failed = false
               expectation.fulfill()
           }, onFailure: { _, _ in
               failed = true
               expectation.fulfill()
           })

           wait(for: [expectation], timeout: 100)

           XCTAssert(!failed)
       }

       func testInvalidCertificate() {
           let expectation = XCTestExpectation(description: "testInvalidCertificate")
           var failed = true

           let request = TNRequest(route: APIRoute.testPinning(certPath: invalidCertPath))
           request.start(responseType: String.self, onSuccess: { _ in
               failed = true
               expectation.fulfill()
           }, onFailure: { _, _ in
               failed = false
               expectation.fulfill()
           })

           wait(for: [expectation], timeout: 100)

           XCTAssert(!failed)
       }
}
