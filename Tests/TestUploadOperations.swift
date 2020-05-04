// TestTNRequest.swift
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

class TestUploadOperations: XCTestCase {
    lazy var configuration: TNConfiguration = {
        return TNConfiguration(verbose: true)
    }()

    lazy var router: TNRouter<APIRoute> = {
        return TNRouter<APIRoute>(environment: Environment.termiNetworkLocal,
                                  configuration: configuration)
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

    class FileResponse: Decodable {
        var success: Bool
    }

    func testMultipartBoundary() {
        let boundary1 = TNMultipartFormDataHelpers.generateBoundary()
        let boundary2 = TNMultipartFormDataHelpers.generateBoundary()
        XCTAssert(boundary1 != boundary2)
    }

    func testDataUpload() {
        let expectation = XCTestExpectation(description: "testDataUpload")
        var failed = true

        guard let filePath = Bundle(for: TestUploadOperations.self).path(forResource: "dummyfile", ofType: ""),
        let uploadData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            assert(false)
        }

        router.request(for: .fileUpload(data: uploadData, param: "yo"))
            .startUpload(responseType: FileResponse.self,
                         progressUpdate: { progress in
                                debugPrint(progress)
            }, onSuccess: { response in
                failed = response.success
                expectation.fulfill()

            }, onFailure: { (_, _) in
                expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }
}
