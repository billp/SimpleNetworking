// UIHelpers.swift
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

class UIHelpers {
    static let textFieldBackgroundColor = Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0)

    static func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .bold()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    static func customTextField(_ title: String,
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

    static func button(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.white)
        }
        .padding(10)
        .background(Color.blue)
        .cornerRadius(5)
        .clipped()
    }
}
