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

enum TNMultipartBodyPart {
    case data(Data)
    case stream(Stream)
}

class TNMultipartFormDataStream: NSObject, StreamDelegate {
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }

    lazy var boundStreams: Streams = {
        var inputOrNil: InputStream?
        var outputOrNil: OutputStream?
        Stream.getBoundStreams(withBufferSize: 4096,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both" +
                       "`inputStream` and `outputStream` will contain non-nil streams.")
        }
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .current, forMode: .default)
        output.open()
        return Streams(input: input, output: output)
    }()

    var bodyParts: [TNMultipartBodyPart] = []

    init(params: [String: Any?],
         boundary: String) {
        super.init()
        createBodyParts(with: params,
                        boundary: boundary)
    }

    func processNextBodyPart() {
        guard bodyParts.count > 0 else {
            return
        }

        let part = bodyParts.removeFirst()

        switch part {
        case .data(let data):
            _ = data.withUnsafeBytes { buffer in
                boundStreams.output.write(buffer.bindMemory(to: UInt8.self).baseAddress!,
                                          maxLength: data.count)
            }
        default:
            break
        }

        processNextBodyPart()
    }

    fileprivate func generatePart(withData data: Data,
                                  boundary: String,
                                  param: String,
                                  shouldOpenBody: Bool,
                                  isLastPart: Bool,
                                  fileName: String? = nil) -> Data {
        let finalData = NSMutableData()
        if shouldOpenBody {
            finalData.append(TNMultipartFormDataHelpers.openBodyPart(boundary: boundary))
        }
        finalData.append(TNMultipartFormDataHelpers.generateContentDisposition(boundary: boundary,
                                                                               name: param,
                                                                               filename: fileName))
        finalData.append(data)
        finalData.append(TNMultipartFormDataHelpers.closeBodyPart(boundary: boundary,
                                                                  isLastPart: isLastPart))

        return finalData as Data
    }

    fileprivate func createBodyParts(with params: [String: Any?],
                                     boundary: String) {
        params.keys.enumerated().forEach { (index, key) in
            let value = params[key]
            let shouldOpenBody = index == 0
            let isLastPart = index == params.keys.count - 1

            if let data = value as? Data {
                let finalData = generatePart(withData: data,
                                             boundary: boundary,
                                             param: key,
                                             shouldOpenBody: shouldOpenBody,
                                             isLastPart: isLastPart,
                                             fileName: key)

                bodyParts.append(.data(finalData as Data))
            } else if let value = value as? String {
                let finalData = generatePart(withData: value.data(using: .utf8) ?? Data(),
                                             boundary: boundary,
                                             param: key,
                                             shouldOpenBody: shouldOpenBody,
                                             isLastPart: isLastPart)

                bodyParts.append(.data(finalData as Data))
            } else if let url = value as? URL, let stream = InputStream(url: url) {
                bodyParts.append(.stream(stream))
            }
        }
    }
}
