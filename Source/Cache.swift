// Cache.swift
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

/// Cache is used internally for various tasks such as in-memory caching image data.
/// Primarily used in UIImageView|NSImageView|WKInterfaceImage and Image (SwiftUI) helpers.
public final class Cache {
    /// Singleton object.
    public static let shared = Cache()

    /// Singleton definition
    let cache: NSCache<NSString, NSData> = NSCache()

    /// Configures the cache.
    /// - Parameters:
    ///     - countLimit: The maximum number of objects the cache will hold.
    ///     - size: The maximum total size (in bytes) the cache will hold before it starts removing objects.
    public func configureCache(countLimit: Int, size: Int) {
        cache.countLimit = countLimit
        cache.totalCostLimit = size
    }

    /// Clears cache.
    public func clearCache() {
        cache.removeAllObjects()
    }

    /// :nodoc:
    subscript(key: String) -> Data? {
        get {
            cache.object(forKey: key as NSString) as Data?
        }
        set {
            guard let data = newValue as NSData? else {
                return
            }
            cache.setObject(data, forKey: key as NSString)
        }
    }
}
