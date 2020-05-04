// TNSessionTaskFactory.swift
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

class TNUploadTaskInputStream: InputStream, StreamDelegate {
    fileprivate var _streamStatus: Stream.Status = .notOpen
    fileprivate weak var _delegate: StreamDelegate?
    fileprivate var params: [String: Any?] = [:]
    fileprivate var boundary: String

    init(withParams params: [String: Any?], boundary: String) {
        self.params = params
        self.boundary = boundary

        super.init(data: Data())
    }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        let data = "yo=test".data(using: .utf8)
        data?.copyBytes(to: buffer, count: data?.count ?? 0)
        return 0
    }

    override var hasBytesAvailable: Bool {
        return true
    }

    override var streamStatus: Stream.Status {
        return _streamStatus
    }

    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {

    }

    override func close() {

    }

    override func property(forKey key: Stream.PropertyKey) -> Any? {
        return nil
    }

    override func open() {
        _streamStatus = .closed
    }

    override var delegate: StreamDelegate? {
        set { _delegate = newValue }
        get { return _delegate }
    }

}
