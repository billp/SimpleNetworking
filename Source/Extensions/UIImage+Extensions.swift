// UIImage+Extensions.swift
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

#if os(macOS)
extension ImageType {
    // MARK: Resizing
    /// Resize the image to the given size.
    ///
    /// - Parameter
    ///     - size: The size to resize the image to.
    /// - Returns: The resized image.
    func tn_resize(_ targetSize: NSSize) -> ImageType? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = ImageType(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
    }
}
#elseif os(iOS) || os(watchOS) || os(tvOS)
import UIKit

extension ImageType {
    ///
    /// Resizes an UIImage object.
    ///
    /// - parameters:
    ///     - size: The size of the new image.
    /// - returns: The new resized UIImage object.
    func tn_resize(_ targetSize: CGSize) -> ImageType? {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        let scaleFactor = min(widthRatio, heightRatio)

        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        #if os(watchOS)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        _ = UIGraphicsGetCurrentContext()!
        self.draw(in: CGRect(x: 0, y: 0, width: scaledImageSize.width, height: scaledImageSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
        #else
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        #endif

        return scaledImage
    }
}
#endif
