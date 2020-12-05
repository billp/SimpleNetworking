// TNImage.swift
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

import Foundation
import Combine
import SwiftUI

public typealias PreprocessImageType = ((UIImage) -> (UIImage))

final private class ImageLoader: ObservableObject {
    var url: String
    var configuration: TNConfiguration?
    var defaultImage: UIImage?
    var resize: CGSize?
    var preprocessImageClosure: PreprocessImageType?

    var didChange = PassthroughSubject<UIImage, Never>()
    var image = UIImage() {
        didSet {
            didChange.send(image)
        }
    }

    public init(with url: String,
                configuration: TNConfiguration? = nil,
                defaultImage: UIImage? = nil,
                resize: CGSize? = nil,
                preprocessImage: PreprocessImageType? = nil) {
        self.url = url
        self.configuration = configuration
        self.defaultImage = defaultImage
        self.resize = resize
        self.preprocessImageClosure = preprocessImage
    }

    func loadImage() {
        if let cachedImageData = TNCache.shared[url],
           let image = UIImage(data: cachedImageData) {
            self.image = image
            return
        }

        self.image = defaultImage ?? UIImage()

        TNRequest(method: .get,
                  url: url,
                  configuration: configuration).start(responseType: UIImage.self) { image in
                    self.handleResizeImage(image: image)
                    self.handlePreprocessImage(image: image)
        }
    }

    // MARK: Helpers
    private func updateImage(_ image: UIImage) {
        self.image = image
        TNCache.shared[self.url] = image.pngData()
    }

    private func handlePreprocessImage(image: UIImage) {
        var image = image
        if let preprocessImage = self.preprocessImageClosure {
            DispatchQueue.global(qos: .background).async {
                image = preprocessImage(image)

                DispatchQueue.main.async {
                    self.updateImage(image)
                }
            }
        } else {
            updateImage(image)
        }
    }
    private func handleResizeImage(image: UIImage) {
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
    @ObservedObject private var imageLoader: ImageLoader
    @State var image = UIImage()

    public var body: some View {
        Image(uiImage: image)
            .resizable()
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
    ///     - defaultImage: A UIImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread (optional)
    public init(withUrl url: String,
                configuration: TNConfiguration? = nil,
                defaultImage: UIImage? = nil,
                resize: CGSize? = nil,
                preprocessImage: PreprocessImageType? = nil) {
        self.imageLoader = ImageLoader(with: url,
                                       configuration: configuration,
                                       defaultImage: defaultImage,
                                       resize: resize,
                                       preprocessImage: preprocessImage)
    }
}
