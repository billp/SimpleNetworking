// TNFileStreamer.swift
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

typealias ChunkType = (Data?) -> Void

class TNFileStreamer: NSObject, StreamDelegate {

    var nextChunkClosure: ChunkType?
    var inputStream: InputStream?
    var bufferSize: Int = 1028
    var fileSize: Int = -1
    var bytesRead: Int = 0

    lazy var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

    init(url: URL, bufferSize: Int) {
        super.init()
        self.bufferSize = bufferSize
        self.fileSize = TNMultipartFormDataHelpers.fileSize(withURL: url)

        inputStream = InputStream(url: url)
        inputStream?.schedule(in: .current, forMode: .default)
        inputStream?.open()
    }

    func readNextChunk(nextChunkClosure: ChunkType? = nil) throws {
        if let inputStream = inputStream, inputStream.hasBytesAvailable {
            if inputStream.hasBytesAvailable {
                let bytesLeft = fileSize - bytesRead
                let maxLength = bytesLeft >= bufferSize ? bufferSize : bytesLeft
                let read = inputStream.read(buffer, maxLength: maxLength)
                if read < 0 {
                   throw inputStream.streamError!
                } else if read > 0 {
                    bytesRead += read
                    nextChunkClosure?(Data(bytes: buffer, count: read))
                } else {
                    nextChunkClosure?(nil)
                }
            }
        }
    }
}
