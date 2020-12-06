// TNMultipartFormDataStream.swift
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

enum TNMultipartBodyPart {
    case data(Data)
    case stream(stream: TNFileStreamer, fileURL: URL)
}

internal class TNMultipartFormDataStream: NSObject, StreamDelegate {
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }

    struct Constants {
        static var bufferSize = 1024 * 1024
    }

    lazy var boundStreams: Streams = {
        var inputOrNil: InputStream?
        var outputOrNil: OutputStream?

        Stream.getBoundStreams(withBufferSize: Constants.bufferSize,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both" +
                       "`inputStream` and `outputStream` will contain non-nil streams.")
        }
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .current, forMode: .default)
        return Streams(input: input, output: output)
    }()

    fileprivate var bodyParts: [TNMultipartBodyPart] = []
    fileprivate var currentBodyPart: TNMultipartBodyPart?
    fileprivate var bytesLeft: Int = 0
    fileprivate var bytesSent: Int = 0
    fileprivate var currentBytesSent: Int = -1
    fileprivate var totalBytes: Int = 0
    fileprivate var currentOffset: Int = 0
    fileprivate var uploadProgressCallback: TNProgressCallbackType?
    fileprivate weak var request: TNRequest?

    init(request: TNRequest,
         params: [String: TNMultipartFormDataPartType],
         boundary: String,
         uploadProgressCallback: TNProgressCallbackType?) throws {
        self.uploadProgressCallback = uploadProgressCallback
        self.request = request

        super.init()
        try createBodyParts(with: params,
                            boundary: boundary)
        processNextBodyPart()
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if aStream == boundStreams.output {
            if bytesLeft > 0 && boundStreams.output.hasSpaceAvailable {
                try? processData()
            } else if bodyParts.count == 0 {
                aStream.close()
            }
        }
    }

    func processData() throws {
        switch currentBodyPart {
        case .data(let data):
            processNextDataChunk(data)
        case .stream(let stream, _):
            try stream.readNextChunk(seekToOffset: currentBytesSent+1) { [weak self] data in
                if let data = data, data.count > 0 {
                    self?.processNextDataChunk(data)
                } else {
                    self?.processNextBodyPart()
                }
            }
        default:
            break
        }
    }

    fileprivate func processNextBodyPart() {
        guard bodyParts.count > 0 else {
            return
        }
        currentBodyPart = bodyParts.removeFirst()

        if case .data(let data) = currentBodyPart {
            bytesLeft = data.count
        } else if case .stream(_,
                               let url) = currentBodyPart {
            bytesLeft = TNMultipartFormDataHelpers.fileSize(withURL: url)

        }
    }

    // MARK: Helpers
    fileprivate func generatePart(withData data: Data,
                                  boundary: String,
                                  param: String,
                                  shouldOpenBody: Bool,
                                  isLastPart: Bool,
                                  filename: String? = nil,
                                  contentType: String? = nil) -> Data {
        let finalData = NSMutableData()
        if shouldOpenBody {
            finalData.append(TNMultipartFormDataHelpers.openBodyPart(boundary: boundary))
        }
        finalData.append(TNMultipartFormDataHelpers.generateContentDisposition(boundary: boundary,
                                                                               name: param,
                                                                               filename: filename,
                                                                               contentType: contentType))
        finalData.append(data)
        finalData.append(TNMultipartFormDataHelpers.closeBodyPart(boundary: boundary,
                                                                  isLastPart: isLastPart))

        return finalData as Data
    }

    fileprivate func createBodyParts(with params: [String: TNMultipartFormDataPartType],
                                     boundary: String) throws {
        totalBytes = 0

        try params.keys.enumerated().forEach { (index, key) in
            guard let value = params[key] else {
                return
            }
            let shouldOpenBody = index == 0
            let isLastPart = index == params.keys.count - 1

            if case .value(let value) = value,
                let data = value.data(using: .utf8) {

                let finalData = generatePart(withData: data,
                                             boundary: boundary,
                                             param: key,
                                             shouldOpenBody: shouldOpenBody,
                                             isLastPart: isLastPart)
                totalBytes += finalData.count
                bodyParts.append(.data(finalData as Data))
            } else if case .data(let data, let filename, let contentType) = value {
                let finalData = generatePart(withData: data,
                                             boundary: boundary,
                                             param: key,
                                             shouldOpenBody: shouldOpenBody,
                                             isLastPart: isLastPart,
                                             filename: filename ?? key,
                                             contentType: contentType)
                totalBytes += finalData.count
                bodyParts.append(.data(finalData as Data))
            } else if case .url(let url) = value {
                guard url.isFileURL else {
                    throw TNError.invalidFileURL(url.absoluteString)
                }
                totalBytes += createStreamBodyPart(withUrl: url,
                                                   shouldOpenBody:
                                                    shouldOpenBody,
                                                   isLastPart: isLastPart,
                                                   boundary: boundary,
                                                   key: key)
            }
        }
    }

    fileprivate func createStreamBodyPart(withUrl url: URL,
                                          shouldOpenBody: Bool,
                                          isLastPart: Bool,
                                          boundary: String,
                                          key: String) -> Int {
        var bytes = 0
        let stream = TNFileStreamer(url: url, bufferSize: Constants.bufferSize)
        if shouldOpenBody {
            let openBodyData = TNMultipartFormDataHelpers.openBodyPart(boundary: boundary)
            bodyParts.append(.data(openBodyData))
            bytes += openBodyData.count
        }
        let formData = TNMultipartFormDataHelpers
            .generateContentDisposition(
                        boundary: boundary,
                        name: key,
                        filename: url.lastPathComponent,
                        contentType: TNMultipartFormDataHelpers.mimeTypeForPath(path: url.path))
        bodyParts.append(.data(formData))
        bytes += formData.count

        bodyParts.append(.stream(stream: stream, fileURL: url))
        bytes += TNMultipartFormDataHelpers.fileSize(withURL: url)

        let closeBodyData = TNMultipartFormDataHelpers.closeBodyPart(boundary: boundary,
                                                                     isLastPart: isLastPart)
        bodyParts.append(.data(closeBodyData))
        bytes += closeBodyData.count

        return bytes
    }

    fileprivate func processNextDataChunk(_ data: Data) {
        let count = data.count

        data.withUnsafeBytes { buffer in
            var maxLength = 0
            if case .stream(_, _) = currentBodyPart {
                currentOffset = 0
                maxLength = count < Constants.bufferSize ? count : Constants.bufferSize
            } else {
                maxLength = bytesLeft >= Constants.bufferSize ? Constants.bufferSize : bytesLeft
            }

            let memoryOffset = buffer.bindMemory(to: UInt8.self).baseAddress!
                                + currentOffset

            let bytesWritten = boundStreams.output.write(memoryOffset,
                                                         maxLength: maxLength)

            if bytesWritten == -1 {
                return
            }

            bytesLeft -= bytesWritten
            bytesSent += bytesWritten
            currentBytesSent += bytesWritten
            currentOffset += bytesWritten

            let progress = Float(bytesSent) / Float(totalBytes)

            TNLog.logProgress(request: request,
                              bytesProcessed: self.bytesSent,
                              totalBytes: self.totalBytes,
                              progress: progress)
            self.uploadProgressCallback?(self.bytesSent, self.totalBytes, progress)

            if bytesLeft == 0 {
                currentOffset = 0
                currentBytesSent = -1
                processNextBodyPart()
            }
        }
    }
}
