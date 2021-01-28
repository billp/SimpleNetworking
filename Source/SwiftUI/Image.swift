// Image.swift
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

import Foundation
import Combine
import SwiftUI

#if os(macOS)
/// The Image type depending on platform: UIImage for iOS or NSImage for macOS.
public typealias ImageType = NSImage
#elseif os(iOS) || os(watchOS) || os(tvOS)
/// The Image type depending on platform: UIImage for iOS or NSImage for macOS.
public typealias ImageType = UIImage
#endif

/// Callback type for image preprocess used in UIImageView|NSImage|WKInterfaceImage and Image (SwiftUI) helpers
/// - parameters:
///     - image: The downloaded image.
/// - returns: The new transformed image.
public typealias ImagePreprocessType = (_ image: ImageType) -> (ImageType)
/// Callback type for image downloaded event.
/// - parameters:
///     - image: The downloaded image.
///     - error: A TNError object if it fails to download.
/// - returns: The new transformed image.
public typealias ImageOnFinishCallbackType = (_ image: ImageType?, _ error: TNError?) -> Void

@available(iOS 13.0, *)
/// :nodoc:
final public class ImageLoader: ObservableObject {
    var request: Request
    var url: String?
    var defaultImage: ImageType?
    var resize: CGSize?
    var preprocessImageClosure: ImagePreprocessType?
    var onFinishImageClosure: ImageOnFinishCallbackType?

    var didChange = PassthroughSubject<ImageType, Never>()
    var image = ImageType() {
        didSet {
            didChange.send(image)
        }
    }

    init(with url: String,
         configuration: Configuration? = nil,
         defaultImage: ImageType? = nil,
         resize: CGSize? = nil,
         preprocessImage: ImagePreprocessType? = nil,
         onFinish: ImageOnFinishCallbackType? = nil) {
        self.url = url
        self.request = Request(method: .get,
                                 url: url,
                                 configuration: configuration)
        self.defaultImage = defaultImage
        self.resize = resize
        self.preprocessImageClosure = preprocessImage
        self.onFinishImageClosure = onFinish
    }

    init(with request: Request,
         defaultImage: ImageType? = nil,
         resize: CGSize? = nil,
         preprocessImage: ImagePreprocessType? = nil,
         onFinish: ImageOnFinishCallbackType? = nil) {
        self.request = request
        self.defaultImage = defaultImage
        self.resize = resize
        self.preprocessImageClosure = preprocessImage
        self.onFinishImageClosure = onFinish
        self.url = try? request.asRequest().url?.absoluteString
    }

    public func loadImage() {
        if let url = url,
           let cachedImageData = Cache.shared[url],
           let image = ImageType(data: cachedImageData) {
            self.image = image
            return
        }

        self.image = defaultImage ?? ImageType()
        request
            .success(responseType: ImageType.self) { image in
                self.handlePreprocessImage(image: image) { preprocessedImage in
                    // Resize image only if preprocess image function is not present
                    if preprocessedImage == nil {
                        self.handleResizeImage(image: image)
                    }
                }
            }
            .failure { error in
                self.onFinishImageClosure?(nil, error)
            }

    }

    // MARK: Helpers
    private func updateImage(_ image: ImageType) {
        self.image = image
        if let url = url {
            #if os(macOS)
            if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                bitmapRep.size = image.size
                Cache.shared[url] = bitmapRep.representation(using: .png, properties: [:])
            }
            #else
                Cache.shared[url] = image.pngData()
            #endif
        }
    }

    private func handlePreprocessImage(image: ImageType,
                                       onFinish: ((ImageType?) -> Void)? = nil) {
        var image = image
        if let preprocessImage = self.preprocessImageClosure {
            DispatchQueue.global(qos: .background).async {
                image = preprocessImage(image)

                DispatchQueue.main.async {
                    self.updateImage(image)
                    self.onFinishImageClosure?(image, nil)
                    onFinish?(image)
                }
            }
        } else {
            onFinish?(nil)
        }
    }
    private func handleResizeImage(image: ImageType,
                                   onFinish: ((ImageType) -> Void)? = nil) {
        if let size = self.resize {
            var image = image
            DispatchQueue.global(qos: .background).async {
                image = image.tn_resize(size) ?? image
                DispatchQueue.main.async {
                    self.updateImage(image)
                    onFinish?(image)
                }
            }
        }
    }
}

/// Image is a SwiftUI component for downloading images.
@available(iOS 13.0, *)
public struct Image: View {
    @ObservedObject internal var imageLoader: ImageLoader
    @State var image = ImageType()

    /// Main body
    public var body: some View {
        #if os(macOS)
        let imageView = SwiftUI.Image(nsImage: image)
        #else
        let imageView = SwiftUI.Image(uiImage: image)
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
    ///     - configuration: A Configuration object that will be used to make the request.
    ///     - defaultImage: A UIImage|NSImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread
    ///     - onFinish: A block of code to execute after the completion of the request.
    ///            If the request fails, an error will be returned
    public init(withURL url: String,
                configuration: Configuration? = nil,
                defaultImage: ImageType? = nil,
                resize: CGSize? = nil,
                preprocessImage: ImagePreprocessType? = nil,
                onFinish: ImageOnFinishCallbackType? = nil) {
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
    ///     - request: A Request instance.
    ///     - configuration: A Configuration object that will be used to make the request.
    ///     - defaultImage: A UIImage|NSImage to show before the is downloaded (optional)
    ///     - resize: Resizes the image to the given CGSize
    ///     - preprocessImage: A block of code that preprocesses the after the download.
    ///     This block will run in the background thread (optional)
    public init(withRequest request: Request,
                defaultImage: ImageType? = nil,
                resize: CGSize? = nil,
                preprocessImage: ImagePreprocessType? = nil,
                onFinish: ImageOnFinishCallbackType? = nil) {
        self.imageLoader = ImageLoader(with: request,
                                       defaultImage: defaultImage,
                                       resize: resize,
                                       preprocessImage: preprocessImage,
                                       onFinish: onFinish)
    }
}
