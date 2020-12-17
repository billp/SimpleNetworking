// TNImage.swift
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

import Foundation
import Combine
import SwiftUI

#if os(macOS)
public typealias TNImageType = NSImage
#elseif os(iOS) || os(watchOS) || os(tvOS)
public typealias TNImageType = UIImage
#endif

public typealias ImagePreprocessType = (TNImageType) -> (TNImageType)
public typealias ImageOnFinishType = (TNImageType?, TNError?) -> Void

final public class ImageLoader: ObservableObject {
    var request: TNRequest
    var url: String?
    var defaultImage: TNImageType?
    var resize: CGSize?
    var preprocessImageClosure: ImagePreprocessType?
    var onFinishImageClosure: ImageOnFinishType?

    var didChange = PassthroughSubject<TNImageType, Never>()
    var image = TNImageType() {
        didSet {
            didChange.send(image)
        }
    }

    public init(with url: String,
                configuration: TNConfiguration? = nil,
                defaultImage: TNImageType? = nil,
                resize: CGSize? = nil,
                preprocessImage: ImagePreprocessType? = nil,
                onFinish: ImageOnFinishType? = nil) {
        self.url = url
        self.request = TNRequest(method: .get,
                                 url: url,
                                 configuration: configuration)
        self.defaultImage = defaultImage
        self.resize = resize
        self.preprocessImageClosure = preprocessImage
        self.onFinishImageClosure = onFinish
    }

    public init(with request: TNRequest,
                defaultImage: TNImageType? = nil,
                resize: CGSize? = nil,
                preprocessImage: ImagePreprocessType? = nil,
                onFinish: ImageOnFinishType? = nil) {
        self.request = request
        self.defaultImage = defaultImage
        self.resize = resize
        self.preprocessImageClosure = preprocessImage
        self.onFinishImageClosure = onFinish
        self.url = try? request.asRequest().url?.absoluteString
    }

    public func loadImage() {
        if let url = url,
           let cachedImageData = TNCache.shared[url],
           let image = TNImageType(data: cachedImageData) {
            self.image = image
            return
        }

        self.image = defaultImage ?? TNImageType()

        request.start(responseType: TNImageType.self, onSuccess: { image in
            self.handleResizeImage(image: image)
            self.handlePreprocessImage(image: image)
        }, onFailure: { (error, _) in
            self.onFinishImageClosure?(nil, error)
        })
    }

    // MARK: Helpers
    private func updateImage(_ image: TNImageType) {
        self.image = image
        if let url = url {
            #if os(macOS)

            #else
                TNCache.shared[url] = image.pngData()
            #endif
        }
    }

    private func handlePreprocessImage(image: TNImageType) {
        var image = image
        if let preprocessImage = self.preprocessImageClosure {
            DispatchQueue.global(qos: .background).async {
                image = preprocessImage(image)

                DispatchQueue.main.async {
                    self.updateImage(image)
                    self.onFinishImageClosure?(image, nil)
                }
            }
        } else {
            updateImage(image)
        }
    }
    private func handleResizeImage(image: TNImageType) {
        if let size = self.resize {
            var image = image
            DispatchQueue.global(qos: .background).async {
                image = image.tn_resize(size) ?? image
                DispatchQueue.main.async {
                    self.updateImage(image)
                }
            }
        }
    }
}

public struct TNImage: View {
    @ObservedObject public var imageLoader: ImageLoader
    @State var image = TNImageType()

    public var body: some View {
        #if os(macOS)
        let imageView = Image(nsImage: image)
        #else
        let imageView = Image(uiImage: image)
        #endif

        imageView.resizable()
            .onReceive(imageLoader.didChange) { image in
            self.image = image
        }.onAppear(perform: self.imageLoader.loadImage)
    }

    ///
    /// Download a remote image with the specified url.
    ///
    /// - parameters:
    ///     - url: The url of the image.
    ///     - configuration: A TNConfiguration object that will be used to make the request.
    ///     - defaultImage: A UIImage|NSImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread
    ///     - onFinish: A block of code to execute after the completion of the request.
    ///            If the request fails, an error will be returned
    public init(with url: String,
                configuration: TNConfiguration? = nil,
                defaultImage: TNImageType? = nil,
                resize: CGSize? = nil,
                preprocessImage: ImagePreprocessType? = nil,
                onFinish: ImageOnFinishType? = nil) {
        self.imageLoader = ImageLoader(with: url,
                                       configuration: configuration,
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
    ///     - configuration: A TNConfiguration object that will be used to make the request.
    ///     - defaultImage: A UIImage|NSImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread (optional)
    public init(with request: TNRequest,
                defaultImage: TNImageType? = nil,
                resize: CGSize? = nil,
                preprocessImage: ImagePreprocessType? = nil,
                onFinish: ImageOnFinishType? = nil) {
        self.imageLoader = ImageLoader(with: request,
                                       defaultImage: defaultImage,
                                       resize: resize,
                                       preprocessImage: preprocessImage,
                                       onFinish: onFinish)
    }
}
