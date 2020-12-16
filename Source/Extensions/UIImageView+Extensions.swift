// UIImageView+Extensions.swift
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

#if os(iOS)

import UIKit

extension UIImageView {
    private static var activeRequestsDictionary: [String: TNRequest] = [:]
    private static var imageViewQueue: TNQueue = TNQueue()

    fileprivate static func downloadImage(request: TNRequest,
                                          onSuccess: @escaping TNSuccessCallback<UIImage>,
                                          onFailure: @escaping TNFailureCallback) throws -> TNRequest {
        request.start(queue: imageViewQueue,
                      responseType: UIImage.self,
                      onSuccess: onSuccess,
                      onFailure: onFailure)

        return request
    }

    ///
    /// Download a remote image with the specified url.
    ///
    /// - parameters:
    ///     - url: The url of the image.
    ///     - configuration: A TNConfiguration object that will be used to make the request.
    ///     - defaultImage: A UIImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread (optional)
    ///     - onFinish: A block of code to execute after the completion of the download image request.
    ///            If the request fails, an error will be returned (optional)
    public func tn_setRemoteImage(url: String,
                                  configuration: TNConfiguration? = nil,
                                  defaultImage: UIImage? = nil,
                                  resize: CGSize? = nil,
                                  preprocessImage: ImagePreprocessType? = nil,
                                  onFinish: ImageOnFinishType? = nil) throws {

        try makeRequest(with: TNRequest.init(method: .get,
                                             url: url,
                                             configuration: configuration),
                        defaultImage: defaultImage,
                        resize: resize,
                        preprocessImage: preprocessImage,
                        onFinish: onFinish)
    }

    ///
    /// Download a remote image with the specified url.
    ///
    /// - parameters:
    ///     - request: A TNRequest instance.
    ///     - defaultImage: A UIImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread (optional)
    ///     - onFinish: A block of code to execute after the completion of the download image request.
    ///            If the request fails, an error will be returned (optional)
    public func tn_setRemoteImage(request: TNRequest,
                                  defaultImage: UIImage? = nil,
                                  resize: CGSize? = nil,
                                  preprocessImage: ImagePreprocessType? = nil,
                                  onFinish: ImageOnFinishType? = nil) throws {

        try makeRequest(with: request,
                        defaultImage: defaultImage,
                        resize: resize,
                        preprocessImage: preprocessImage,
                        onFinish: onFinish)
    }

    // MARK: Helpers
    private func makeRequest(with request: TNRequest,
                             defaultImage: UIImage? = nil,
                             resize: CGSize? = nil,
                             preprocessImage: ImagePreprocessType? = nil,
                             onFinish: ImageOnFinishType? = nil) throws {
        cancelActiveCallInImageView()
        self.image = defaultImage

        setActiveCallInImageView(try UIImageView.downloadImage(request: request,
                                                               onSuccess: { image in
            var image = image

            DispatchQueue.global(qos: .background).async {
                image = preprocessImage?(image) ?? image

                if let resize = resize {
                    image = image.tn_resize(resize) ?? image
                }

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
#endif
