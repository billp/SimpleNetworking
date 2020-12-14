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
            fieldLabel("Encryption Key")
            customTextField("Encryption key", text: $encryptionKey, onChange: { val in
                CryptoMiddleware.encryptionKey = val
            })
            fieldLabel("Decryption Key")
            customTextField("Decryption key", text: $decryptionKey, onChange: { val in
                CryptoMiddleware.decryptionKey = val
            })
            fieldLabel("Text")
            customTextField("Value", text: $text)
            fieldLabel("Response (if the decryption succeeds, it will show same value as in 'Text' field).")
            TextEditor(text: $responseString)
                .font(.footnote)
                .background(textFieldBackgroundColor)
                .cornerRadius(5)
                .clipped()
            Button(action: startRequest) {
                Text("Start Request")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(Color.blue)
            .cornerRadius(5)
            .clipped()
            .padding(.bottom, 20)
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle("Encryption Layer")
    }

    // MARK: Communication
    func startRequest() {
        TNRouter<MiscRoute>(configuration: configuration).request(for: .testEncryptParams(param: text))
            .start(transformer: EncryptedModelTransformer.self, onSuccess: { model in
            responseString = model.text
        }, onFailure: { (error, _) in
            responseString = error.localizedDescription ?? ""
        })
    }

    // MARK: Helpers
    func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .bold()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    func customTextField(_ title: String,
                         text: Binding<String>,
                         onChange: ((String) -> Void)? = nil) -> some View {
        TextField(title,
                  text: text,
                  onEditingChanged: { _ in onChange?(text.wrappedValue) })
            .padding(5)
            .background(textFieldBackgroundColor)
            .font(.footnote)
            .cornerRadius(3.0)
            .clipped()
    }
}
