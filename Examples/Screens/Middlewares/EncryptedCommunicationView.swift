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
            Text("Encryption Key")
                .font(.caption)
                .bold()
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            TextField("Encryption key", text: $encryptionKey)
                .padding(5)
                .background(textFieldBackgroundColor)
                .font(.footnote)
                .cornerRadius(3.0)
                .clipped()
            Text("Decryption Key")
                .font(.caption)
                .bold()
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            TextField("Decryption key", text: $decryptionKey)
                .padding(5)
                .background(textFieldBackgroundColor)
                .font(.footnote)
                .cornerRadius(3.0)
                .clipped()
            Text("Text")
                .font(.caption)
                .bold()
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            TextField("Value", text: $text)
                .padding(5)
                .background(textFieldBackgroundColor)
                .font(.footnote)
                .cornerRadius(3.0)
                .clipped()

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
}
