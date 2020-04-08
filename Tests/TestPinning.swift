//
//  TestTNQueue.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 30/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import TermiNetwork

class TestPinning: XCTestCase {

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
           let expectation = XCTestExpectation(description: "Test Not Success")
           var failed = true

           let request = TNRequest(route: APIRouter.testPinning(certName: "herokuapp.com.cer"))
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
           let expectation = XCTestExpectation(description: "Test Not Success")
           var failed = true

           let request = TNRequest(route: APIRouter.testPinning(certName: "forums.swift.org.cer"))
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
