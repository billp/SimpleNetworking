//
//  TestTNCall.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

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
