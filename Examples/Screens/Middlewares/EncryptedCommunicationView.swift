// EncryptedCommunicationView.swift
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

struct EncryptedCommunicationView: View {
    @State var encryptionKey: String = CryptoMiddleware.encryptionKey
    @State var decryptionKey: String = CryptoMiddleware.decryptionKey
    @State var text: String = "Hello!!!"
    @State var responseString: String = "Press Start Request..."

    var configuration: TNConfiguration {
        let configuration = TNConfiguration()
        configuration.requestBodyType = .JSON
        configuration.requestMiddlewares = [CryptoMiddleware.self]
        return configuration
    }

    let textFieldBackgroundColor = Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0)

    var body: some View {
        VStack {
            UIHelpers.fieldLabel("Encryption Key")
            UIHelpers.customTextField("Encryption key", text: $encryptionKey, onChange: { val in
                CryptoMiddleware.encryptionKey = val
            })
            UIHelpers.fieldLabel("Decryption Key")
            UIHelpers.customTextField("Decryption key", text: $decryptionKey, onChange: { val in
                CryptoMiddleware.decryptionKey = val
            })
            UIHelpers.fieldLabel("Text")
            UIHelpers.customTextField("Value", text: $text)
            UIHelpers.fieldLabel("Response (if the decryption succeeds, it will show same value as in 'Text' field).")
            TextEditor(text: $responseString)
                .font(.footnote)
                .background(textFieldBackgroundColor)
                .cornerRadius(5)
                .clipped()
            UIHelpers.button("Start Request", action: startRequest)
                .padding(.bottom, 20)

        }
        .padding([.leading, .trailing], 20)
        .navigationTitle("Encryption Layer")
    }

    // MARK: Communication
    func startRequest() {
        responseString = "fetching..."

        TNRouter<MiscRoute>(configuration: configuration).request(for: .testEncryptParams(param: text))
            .start(transformer: EncryptedModelTransformer.self, onSuccess: { model in
            responseString = model.text
        }, onFailure: { (error, _) in
            responseString = error.localizedDescription ?? ""
        })
    }
}
