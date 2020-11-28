// TNRequest+Mock.swift
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
