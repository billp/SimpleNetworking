// FileDownloader.swift
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
import SwiftUI
import TermiNetwork

struct FileDownloader: View {
    @State var fileURL: String = "https://releases.ubuntu.com/20.04.1/ubuntu-20.04.1-desktop-amd64.iso"
    @State var fileName: String = "ubuntu-20.04.1-desktop-amd64.iso"
    @State var progress: Float = 0
    @State var bytesDownloaded: Int = 0
    @State var bytesTotal: Int = 0
    @State var downloadStarted: Bool = false
    @State var downloadFinished: Bool = false
    @State var error: String?
    @State var outputFile: String = ""
    @State var request: Request?

    var body: some View {
        VStack {
            UIHelpers.fieldLabel("File URL")
            UIHelpers.customTextField("File URL...", text: $fileURL, onChange: updateFilename)
            UIHelpers.fieldLabel("Filename")
            UIHelpers.customTextField("Filename...", text: $fileName)
            if downloadStarted {
                if bytesTotal > 0 {
                    ProgressView(value: progress, total: 100)
                        .padding(.top, 5)
                    Text(String(format: "%.1f of %.1f MB downloaded.",
                                Float(bytesDownloaded)/1024/1024,
                                Float(bytesTotal)/1024/1024))
                        .font(.footnote)
                        .padding(.top, 10)
                } else {
                    ProgressView()
                        .padding(.top, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                }
            }
            if downloadFinished {
                UIHelpers.fieldLabel("File saved at")
                UIHelpers.customTextField("File URL...", text: $outputFile)
            }
            if let error = error {
                Text(error)
                    .padding(.top, 10)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            Spacer()
            UIHelpers.button(!downloadStarted ? "Start Download" : "Stop Download",
                             action: downloadAction)
                .padding(.bottom, 20)
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle("File Downloader")
        .onDisappear(perform: clearAndCancelDownload)
    }

    // MARK: UI Helpers
    func updateFilename(_ url: String) {
        self.fileName = String(url.split(separator: "/").last ?? "")
    }

    // MARK: Actions
    func downloadAction() {
        guard !downloadStarted else {
            clearAndCancelDownload()
            return
        }

        downloadFile()
        downloadStarted = true
        downloadFinished = false
    }

    // MARK: Helpers
    func downloadFile() {
        // Enable verbose
        let configuration = Configuration()
        configuration.verbose = true

        // Construct the final path of the downloaded file
        outputFile = documentsDirectory().appendingPathComponent(fileName).path

        // Remove old file if exists
        removeFileIfNeeded(at: outputFile)

        // Reset download
        error = nil
        resetDownload()

        // Start the request
        request = Request(method: .get,
                          url: fileURL,
                          configuration: configuration)
            .startDownload(filePath: outputFile,
                           progressUpdate: { (bytesDownloaded, bytesTotal, progress) in
                            self.progress = progress * 100
                            self.bytesDownloaded = bytesDownloaded
                            self.bytesTotal = bytesTotal
                           },
                           onSuccess: {
                            self.downloadStarted = false
                            self.downloadFinished = true
                           },
                           onFailure: { error, _ in
                            self.error = error.localizedDescription ?? ""
                            resetDownload()
                           })
    }

    func removeFileIfNeeded(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    func resetDownload() {
        downloadStarted = false
        downloadFinished = false
        bytesTotal = 0
        bytesDownloaded = 0
    }

    func clearAndCancelDownload() {
        request?.cancel()
        resetDownload()
    }

    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
