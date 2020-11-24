//
//  TestHelpers.swift
//  TermiNetworkTests
//
//  Created by Vasilis Panagiotopoulos on 25/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import CommonCrypto

class TestHelpers {
    static func writeDummyFile() -> URL? {
        guard let fileURL = try? FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: false).appendingPathComponent("dummy.txt") else {
            return nil
        }

        if let outputStream = OutputStream(url: fileURL, append: true) {
            outputStream.open()

            for _ in 0..<10 {
                let text = TestHelpers.randomString(length: 1024 * 20)
                let bytesWritten = outputStream.write(text, maxLength: text.count)
                if bytesWritten < 0 { print("write failure") }
            }

            outputStream.close()
        } else {
            print("Unable to open file")
        }

        return fileURL
    }

    static func randomString(length: Int) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }

    static func sha256(url: URL) -> String? {
        do {
            let bufferSize = 1024 * 1024
            // Open file for reading:
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            // Create and initialize SHA256 context:
            var context = CC_SHA256_CTX()
            CC_SHA256_Init(&context)

            // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
            while autoreleasepool(invoking: {
                // Read up to `bufferSize` bytes
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_SHA256_Update(&context, $0, numericCast(data.count))
                    }
                    // Continue
                    return true
                } else {
                    // End of file
                    return false
                }
            }) { }

            // Compute the SHA256 digest:
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_SHA256_Final($0, &context)
            }
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            print(error)
            return nil
        }
    }

}

