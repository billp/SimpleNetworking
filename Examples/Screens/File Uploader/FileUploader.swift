// FileUploader.swift
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import SwiftUI
import TermiNetwork

struct FileUploader: View {
    @State var fileName: String = ""
    @State var fileChecksum: String?
    @State var uploadedFileChecksum: String?
    @State var progress: Float = 0
    @State var bytesUploaded: Int = 0
    @State var bytesTotal: Int = 0
    @State var uploadStarted: Bool = false
    @State var uploadFinished: Bool = false
    @State var error: String?
    @State var outputFile: String = ""
    @State var request: TNRequest?
    @State var imageUrl: URL? = nil
    @State var showCaptureImageView: Bool = false

    var body: some View {
        VStack {
            UIHelpers.button("🌄 Select Photo",
                             action: {
                                self.showCaptureImageView.toggle()
                             })
            if imageUrl != nil {
                UIHelpers.fieldLabel("Filename")
                UIHelpers.customTextField("Filename...", text: $fileName)
            }
            if let fileChecksum = fileChecksum {
                Text("Local file checksum")
                    .font(.footnote)
                    .bold()
                    .padding(.top, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    .padding(.bottom, 3)
                Text(fileChecksum)
                    .font(.footnote)
            }
            if let uploadedFileChecksum = uploadedFileChecksum {
                Text("Uploaded file checksum")
                    .font(.footnote)
                    .bold()
                    .padding(.top, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    .padding(.bottom, 3)
                Text(uploadedFileChecksum)
                    .font(.footnote)
            }
            if showCaptureImageView {
                CaptureImageView(isShown: $showCaptureImageView,
                                 imageUrl: $imageUrl,
                                 fileName: $fileName,
                                 checksum: $fileChecksum)
            }
            if uploadStarted {
                if bytesTotal > 0 {
                    ProgressView(value: progress, total: 100)
                        .padding(.top, 5)
                    Text(String(format: "%.1f of %.1f MB uploaded.", Float(bytesUploaded)/1024/1024, Float(bytesTotal)/1024/1024))
                        .font(.footnote)
                        .padding(.top, 10)
                } else {
                    ProgressView()
                        .padding(.top, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                }
            }
            if uploadFinished && fileChecksum == uploadedFileChecksum {
                Text("Success")
                    .font(.footnote)
                    .bold()
                    .padding(.top, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.green)
            }
            if let error = error {
                Text(error)
                    .padding(.top, 10)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            Spacer()
            UIHelpers.button(!uploadStarted ? "Start Upload" : "Stop Upload",
                             action: uploadAction)
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
    func uploadAction() {
        guard !uploadStarted else {
            clearAndCancelDownload()
            return
        }

        uploadFile()
        uploadStarted = true
        uploadFinished = false
    }

    // MARK: Helpers
    func uploadFile() {
        guard let imageUrl = imageUrl else {
            return
        }

        // Enable verbose
        let configuration = TNConfiguration()
        configuration.verbose = true

        // Construct the final path of the downloaded file
        outputFile = documentsDirectory().appendingPathComponent(fileName).path

        // Remove old file if exists
        removeFileIfNeeded(at: outputFile)

        // Reset download
        error = nil
        uploadedFileChecksum = nil

        resetUpload()

        // Start the request

        request = TNRouter<MiscRoute>().request(for: .upload(fileUrl: imageUrl))
                    .startUpload(transformer: FileUploadTransformer.self,
                                 progressUpdate: { (bytesUploaded, bytesTotal, progress) in
                                                self.progress = progress * 100
                                                self.bytesUploaded = bytesUploaded
                                                self.bytesTotal = bytesTotal
                                 },
                                 onSuccess: { response in
                                    self.uploadStarted = false
                                    self.uploadFinished = true
                                    self.uploadedFileChecksum = response.checksum
                                 },
                                 onFailure: { error ,_ in
                                    self.error = error.localizedDescription ?? ""
                                    resetUpload()
                                 })
    }

    func removeFileIfNeeded(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    func resetUpload() {
        uploadStarted = false
        uploadFinished = false
        bytesTotal = 0
        bytesUploaded = 0
    }


    func clearAndCancelDownload() {
        request?.cancel()
        resetUpload()
    }

    func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

struct CaptureImageView {
    @Binding var isShown: Bool
    @Binding var imageUrl: URL?
    @Binding var fileName: String
    @Binding var checksum: String?

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown,
                           url: $imageUrl,
                           fileName: $fileName,
                           checksum: $checksum)
    }
}


extension CaptureImageView: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isCoordinatorShown: Bool
    @Binding var urlInCoordinator: URL?
    @Binding var fileName: String
    @Binding var checksum: String?

    init(isShown: Binding<Bool>,
         url: Binding<URL?>,
         fileName: Binding<String>,
         checksum: Binding<String?>) {
        _isCoordinatorShown = isShown
        _urlInCoordinator = url
        _fileName = fileName
        _checksum = checksum
    }
    func imagePickerController(_ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            return
        }
        urlInCoordinator = url
        isCoordinatorShown = false
        fileName = url.lastPathComponent
        checksum = FileUploaderUtils.sha256(url: url)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isCoordinatorShown = false
    }
}
