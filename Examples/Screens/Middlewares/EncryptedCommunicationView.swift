//
//  EncryptedCommunicationScreen.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 8/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

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
