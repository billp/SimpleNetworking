//
//  UIHelper.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 14/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

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
}
