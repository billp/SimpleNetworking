// TestInterceptors.swift
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

class TestInterceptors: XCTestCase {
    lazy var router: Router<APIRoute> = {
        let configuration = Configuration()
        configuration.interceptors = [GlobalInterceptor.self]
        configuration.verbose = true
        return Router<APIRoute>(configuration: configuration)
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Environment.set(Env.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInterceptorContinue() {
        Environment.set(Env.termiNetworkRemote)

        let expectation = XCTestExpectation(description: "testInterceptorContinue")
        var failed = true

        router.request(for: .testPostParams(value1: false,
                                            value2: 1,
                                            value3: 2,
                                            value4: "",
                                            value5: nil)).start(responseType: TestJSONParams.self,
                                                                onSuccess: { response in
            failed = !(response.param3 == 2)
            expectation.fulfill()
        }, onFailure: { _, _ in
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testInterceptorRetry() {
        Environment.set(Env.invalidHost)

        let expectation = XCTestExpectation(description: "testInterceptorRetry")
        var failed = true

        router.request(for: .testPostParams(value1: false,
                                            value2: 1,
                                            value3: 2,
                                            value4: "",
                                            value5: nil)).start(responseType: TestJSONParams.self,
                                                                onSuccess: { response in
            failed = !(response.param3 == 2)
            expectation.fulfill()
        }, onFailure: { error, _ in
            print(error)
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testInterceptorRetryFileUpload() {
        Environment.set(Env.invalidHost)

        let expectation = XCTestExpectation(description: "testInterceptorRetry")
        var failed = true

        guard let url = Bundle(for: TestUploadOperations.self).url(forResource: "photo",
                                                                   withExtension: "jpg") else {
            XCTAssert(false)
            return
        }

        let checksum = TestHelpers.sha256(url: url)
        var progressSucceded = false
        var successCount = 0

        router.request(for: .fileUpload(url: url, param: "test")).startUpload(
            responseType: FileResponse.self,
            progressUpdate: { bytesSent, totalBytes, progress in
                if bytesSent == totalBytes && progress == 1 {
                    progressSucceded = true
                }
            },
            onSuccess: { response in
                if response.success && response.checksum == checksum {
                    successCount  += 1
                }
                failed = !progressSucceded
                expectation.fulfill()
            },
            onFailure: { _, _ in
                failed = true
                expectation.fulfill()
            })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

    func testInterceptorRetryFileDownload() {
        Environment.set(Env.invalidHost)

        let expectation = XCTestExpectation(description: "testInterceptorRetryFileDownload")

        var failed = true

        guard var cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            XCTAssert(false)
            return
        }
        cacheURL.appendPathComponent("testDownload")

        try? FileManager.default.removeItem(at: cacheURL)

        router.request(for: .fileDownload)
            .startDownload(filePath: cacheURL.path,
                           progressUpdate: { bytesSent, totalBytes, progress in
                if bytesSent == totalBytes && progress == 1 {
                    failed = false
                }
            }, onSuccess: {
                failed = TestHelpers.sha256(url: cacheURL) !=
                    "b64fb87ce1e10bc7aa14e272262753200414f74a3059c5d7afb443c36be06531"

                expectation.fulfill()
            }, onFailure: { (error, _) in
                failed = true
                print(String(describing: error.localizedDescription))
                expectation.fulfill()
        })

        wait(for: [expectation], timeout: 500)

        XCTAssert(!failed)
    }

    func testMultipleInterceptors() {
        Environment.set(Env.termiNetworkLocal)

        let expectation = XCTestExpectation(description: "testMultipleInterceptors")
        var failed = true

        router.configuration?.interceptors?.append(DoNothingInterceptor.self)
        router.configuration?.cachePolicy = .reloadIgnoringLocalCacheData

        let request = router.request(for: .testPostParams(value1: false,
                                                          value2: 1,
                                                          value3: 2,
                                                          value4: "",
                                                          value5: nil))
        request.start(responseType: TestJSONParams.self,
                      onSuccess: { response in
                        failed = !(response.param3 == 2 &&
                                    (request.associatedObject as? NSNumber)?.boolValue == true)
            expectation.fulfill()
        }, onFailure: { _, _ in
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 60)

        XCTAssert(!failed)
    }

}
