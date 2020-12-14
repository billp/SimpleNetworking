//
//  FileDownloader.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 14/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

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
    @State var outputFile: String = ""
    @State var request: TNRequest?

    var body: some View {
        VStack {
            UIHelpers.fieldLabel("File URL")
            UIHelpers.customTextField("File URL...", text: $fileURL, onChange: updateFilename)
            UIHelpers.fieldLabel("Filename")
            UIHelpers.customTextField("Filename...", text: $fileName)
            ProgressView("Progress", value: progress, total: 100)
            if downloadStarted && bytesTotal > 0 {
                Text(String(format: "%i of %i MB downloaded", bytesDownloaded/1024/1024, bytesTotal/1024/1024))
            }
            if downloadFinished {
                UIHelpers.fieldLabel("File saved at")
                UIHelpers.customTextField("File URL...", text: $outputFile)
            }
            Spacer()
            UIHelpers.button("Start Request", action: startDownload)
                .disabled(downloadStarted)
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle("File Downloader")
        .onDisappear(perform: onDisappear)
    }

    func updateFilename(_ url: String) {
        self.fileName = String(url.split(separator: "/").last ?? "")
    }

    func startDownload() {
        let configuration = TNConfiguration()
        configuration.verbose = true

        outputFile = documentsDirectory().appendingPathComponent(fileName).path

        request = TNRequest(method: .get,
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
                           onFailure: { error ,_ in
                            print(error.localizedDescription ?? "")
                           })
        downloadStarted = true
        downloadFinished = false
    }

    func onDisappear() {
        request?.cancel()
    }

    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
