//
//  TestTNRequestResponseErrors.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 05/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import TermiNetwork

class TestTNErrors: XCTestCase {

    var router: TNRouter<APIRouter> {
       return TNRouter<APIRouter>()
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        TNEnvironment.set(Environment.termiNetworkRemote)
    }

    func testEnvironmentNotSetFullUrl() {
        TNEnvironment.current = nil
        let expectation = XCTestExpectation(description: "Test testEnvironmentNotSetFullUrl")
        var failed = true

        TNRequest(method: .get,
                  url: "http://www.google.com",
                  headers: nil,
                  params: nil).start(responseType: Data.self, onSuccess: { _ in
                    failed = false
                    expectation.fulfill()
                  }, onFailure: { error, _ in
                    if case TNError.environmentNotSet = error {
                        failed = true
                    } else {
                        failed = false
                    }
                    expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testEnvironmentNotSetWithRoute() {
        TNEnvironment.current = nil
        let expectation = XCTestExpectation(description: "Test Empty Response Body")
        var failed = true

        router.start(.testPostParams(value1: true, value2: 1, value3: 2, value4: "Dsa", value5: "A"),
                     onSuccess: { _ in
            expectation.fulfill()
        }, onFailure: { error, _ in
            if case TNError.environmentNotSet = error {
                failed = false
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testInvalidURL() {
        do {
            try _ = TNRequest(method: .get, url: "http://εεε.google.κωμ", headers: nil, params: nil).asRequest()
            XCTAssert(false)
        } catch TNError.invalidURL {
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }

    func testValidURL() {
        do {
            try _ = TNRequest(method: .get, url: "http://www.google.com", headers: nil, params: nil).asRequest()
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }

    func testResponseDataIsNotEmpty() {
        let expectation = XCTestExpectation(description: "Test Not Empty Response Body")
        var failed = true

        router.start(.testEmptyBody, onSuccess: { _ in
            expectation.fulfill()
            failed = false
        }, onFailure: { _, _ in
            expectation.fulfill()
            failed = true
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testResponseInvalidImageData() {
        let expectation = XCTestExpectation(description: "Test Empty Response Body")
        var failed = true

        router.start(.testPostParams(value1: false,
                                     value2: 1,
                                     value3: 2,
                                     value4: "",
                                     value5: nil), responseType: UIImage.self, onSuccess: { _ in
            expectation.fulfill()
            failed = true
        }, onFailure: { error, _ in
            expectation.fulfill()
            switch error {
            case .responseInvalidImageData:
                failed = false
            default:
                failed = true
            }
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testResponseValidImageData() {
        let expectation = XCTestExpectation(description: "Test Empty Response Body")
        var failed = true

        router.start(.testImage(imageName: "sample.jpeg"), responseType: UIImage.self, onSuccess: { _ in
            expectation.fulfill()
            failed = false
        }, onFailure: { _, _ in
            expectation.fulfill()
            failed = true
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testResponseCannotDeserialize() {
        let expectation = XCTestExpectation(description: "Test Response Cannot Deserialize")
        var failed = true

        router.start(.testInvalidParams(value1: "a", value2: "b"), responseType: TestParam.self, onSuccess: { _ in
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testResponseCanDeserialize() {
        let expectation = XCTestExpectation(description: "Test Response Can Deserialize")
        var failed = true

        router.start(.testGetParams(value1: false,
                                    value2: 3,
                                    value3: 1.32,
                                    value4: "Test",
                                    value5: nil), responseType: TestParam.self, onSuccess: { _ in
            failed = false
            expectation.fulfill()
        }, onFailure: { error, _ in
            debugPrint("failed with: " + error.localizedDescription)
            failed = true
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testNetworkError() {
        TNEnvironment.set(Environment.invalidHost)

        let expectation = XCTestExpectation(description: "Test Response Network Error")
        var failed = true

        router.start(.testInvalidParams(value1: "a", value2: "b"), onSuccess: { _ in
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testNotSuccess() {
        let expectation = XCTestExpectation(description: "Test Not Success")
        var failed = true

        router.start(.testStatusCode(code: 404), onSuccess: { _ in
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
    }

    func testCancelled() {
        let expectation = XCTestExpectation(description: "Test Not Success")
        var failed = true

        let request = TNRequest(route: APIRouter.testStatusCode(code: 404))
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

        wait(for: [expectation], timeout: 10)

        XCTAssert(!failed)
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
