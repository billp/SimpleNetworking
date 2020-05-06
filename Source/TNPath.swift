// TNPath.swift
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

/// URL path representation based on String components.
public enum TNPath {
    // MARK: Public properties

    /// Returns the constructed path as String based on .path components.
    public var convertedPath: String {
        switch self {
        case .path(let components):
            return components.joined(separator: "/")
        }
    }

    // MARK: Public methods

    /// An enum case that can be used where path is needed. For example: .path(["user", "1", "details"]).
    /// Later you can call covertedPath to construct the path as String (e.g. /user/1/details)
    case path(_ components: [String])
}

/// The type of the path specified in request construction methods.
internal enum SNPathType: Error {
    case relative
    case absolute
}
