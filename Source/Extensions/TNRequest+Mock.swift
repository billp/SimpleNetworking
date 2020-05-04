//
//  TNRequest+Mock.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 2/5/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import UIKit

extension TNRequest {
    internal func shouldMockRequest() -> Bool {
        return self.configuration.useMockData ?? false
    }

    internal func createMockRequest(request: URLRequest,
                                    completionHandler: ((Data, URLResponse?) -> Void)?,
                                    onFailure: TNFailureCallback?) -> URLSessionDataTask {
        let fakeSession = URLSession(configuration: URLSession.shared.configuration)
                            .dataTask(with: request)

        guard let filePath = mockFilePath?.convertedPath else {
            onFailure?(.invalidMockData(path), nil)
            return fakeSession
        }

        if  let filenameWithExt = filePath.components(separatedBy: "/").last,
            let subdirectory = filePath.components(separatedBy: "/").first,
            let filename = filenameWithExt.components(separatedBy: ".").first,
            let url = configuration.mockDataBundle?.url(forResource: filename,
                                                        withExtension: filenameWithExt
                                                            .components(separatedBy: ".").last,
                                                        subdirectory: subdirectory,
                                                        localization: nil),
            let data = try? Data(contentsOf: url) {
            randomizeResponse {
                completionHandler?(data, nil)
            }
        } else {
            randomizeResponse {
                onFailure?(.invalidMockData(self.path), nil)
            }
        }

        return fakeSession
    }

    fileprivate func delay(_ delay: TimeInterval,
                           block: @escaping (() -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }

    fileprivate func randomizer(between min: TimeInterval,
                                and max: TimeInterval) -> TimeInterval {
        var numberGenerator = SystemRandomNumberGenerator()
        return Double.random(in: min..<max, using: &numberGenerator)
    }

    fileprivate func randomizeResponse(block: @escaping (() -> Void)) {
        guard let min = configuration.mockDelay?.min,
            let max = configuration.mockDelay?.max else {
                block()
                return
        }

        delay(randomizer(between: min,
                         and: max), block: block)
    }
}
