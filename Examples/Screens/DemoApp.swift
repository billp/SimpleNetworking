// DemoApp.swift
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

// swiftlint:disable identifier_name

import Foundation
import SwiftUI

struct DemoApp: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var destination: AnyView

    static var Apps: [DemoApp] {
        [
           DemoApp(
               name: "City Explorer",
               description: "Router, Transformers, Codables",
               destination: AnyView(CityExplorerView())
           ),
           DemoApp(
               name: "City Explorer - Offline Mode",
               description: "Router, Transformers, Codables, Mock Data",
               destination: AnyView(CityExplorerView(usesMockData: true))
           ),
           DemoApp(
               name: "Certificate Pinning",
               description: "Man-in-the-middle attack prevention",
               destination: AnyView(CertificatePinningView())
           ),
           DemoApp(
               name: "Encrypted Communication",
               description: "Crypto Middleware",
               destination: AnyView(EncryptedCommunicationView())
           ),
           DemoApp(
               name: "File Uploader",
               description: "Upload files with progress",
               destination: AnyView(FileUploader())
           ),
           DemoApp(
               name: "File Downloader",
               description: "Download files with progress",
               destination: AnyView(FileDownloader())
           )
       ]
    }
}
