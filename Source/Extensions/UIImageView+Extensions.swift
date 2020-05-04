// UIImageView+Extensions.swift
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

import UIKit

extension UIImageView {
    private static var activeRequestsDictionary: [String: TNRequest] = [:]
    private static var imageViewQueue: TNQueue = TNQueue()

    fileprivate static func downloadImage(url: String,
                                          onSuccess: @escaping TNSuccessCallback<UIImage>,
                                          onFailure: @escaping TNFailureCallback) throws -> TNRequest {
        let request = TNRequest(method: .get, url: url, headers: nil, params: nil)
        request.start(queue: imageViewQueue,
                      responseType: UIImage.self,
                      onSuccess: onSuccess,
                      onFailure: onFailure)

        return request
    }

    ///
    /// Set a remote image from url.
    ///
    /// - parameters:
    ///     - url: The url of the remote image
    ///     - defaultImage: the UIImage showed while the image url is downloading (optional)
    ///     - beforeStart: a block of code executed before image download (optional)
    ///     - preprocessImage: a block of code that preprocess the image before showing. It should
    ///            return the new image. This block will run in the background thread (optional)
    ///     - onFinish: a block of code executed after the completion of the download image request.
    ///            It may fail so error will be returned in that case (optional)
    public func tn_setRemoteImage(url: String,
                                  defaultImage: UIImage? = nil,
                                  beforeStart: (() -> Void)? = nil,
                                  preprocessImage: ((UIImage) -> (UIImage))? = nil,
                                  onFinish: ((UIImage?, Error?) -> Void)? = nil) throws {

        self.image = defaultImage

        beforeStart?()

        cancelActiveCallInImageView()

        setActiveCallInImageView(try UIImageView.downloadImage(url: url, onSuccess: { image in
            var image = image

            DispatchQueue.global(qos: .background).async {
                image = preprocessImage?(image) ?? image

                DispatchQueue.main.async {
                    self.image = image
                    onFinish?(image, nil)
                }
            }
        }, onFailure: { error, _ in
            self.image = nil
            onFinish?(nil, error)
        }))
    }

    // MARK: Helpers
    private func getAddress() -> String {
        return String(describing: Unmanaged.passUnretained(self).toOpaque())
    }

    private func cancelActiveCallInImageView() {
        UIImageView.activeRequestsDictionary[getAddress()]?.cancel()
    }

    private func setActiveCallInImageView(_ call: TNRequest) {
        UIImageView.activeRequestsDictionary[getAddress()] = call
    }
}
