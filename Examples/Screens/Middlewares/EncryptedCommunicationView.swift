//
//  EncryptedCommunicationScreen.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 8/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import SwiftUI

struct EncryptedCommunicationView: View {
    @State var encryptionKey: String = "aaaaaaaaaaaaaaaaaaaaaaabcdefg123"
    @State var decryptionKey: String = "aaaaaaaaaaaaaaaaaaaaaaabcdefg123"
    @State var text: String = "Hello!!!"
    @State var responseString: String = "Press Start Request"

    let textFieldBackgroundColor = Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0)

    var body: some View {
        VStack {
            FieldLabel("Encryption Key")
            CustomTextField("Encryption key", text: $encryptionKey)
            FieldLabel("Decryption Key")
            CustomTextField("Decryption key", text: $decryptionKey)
            FieldLabel("Text")
            CustomTextField("Value", text: $text)
            TextEditor(text: $responseString)
                .padding(10)
                .background(textFieldBackgroundColor)
                .cornerRadius(5)
                .clipped()
            Button(action: {}) {
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

    func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .bold()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    func customTextField(_ title: String, text: Binding<String>) -> some View {
        TextField("Decryption key", text: text)
            .padding(5)
            .background(textFieldBackgroundColor)
            .font(.footnote)
            .cornerRadius(3.0)
            .clipped()
    }
}
