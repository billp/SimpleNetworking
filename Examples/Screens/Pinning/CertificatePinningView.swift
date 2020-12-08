//
//  CertificatePinning.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 7/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import SwiftUI
import TermiNetwork

struct CertificatePinningView: View {
    @State var isCertificateValid: Bool = true
    @State var responseString: String = "Press Start Request..."

    init() {
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        VStack {
            TextEditor(text: $responseString)
                .padding(10)
                .background(Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0))
                .cornerRadius(5)
                .clipped()

            Toggle("Valid Certificate", isOn: $isCertificateValid)
                .padding(.top, 10)
                .padding(.bottom, 50)
            Spacer()
            Button(action: startRequest) {
                Text("Start Request")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .padding(10)
            .background(Color.blue)
            .cornerRadius(5)
            .clipped()
            .padding(.bottom, 20)

        }
        .padding([.leading, .trailing], 20)
        .navigationTitle("Certificate Pinning")
    }

    func startRequest() {
        let certificateName = isCertificateValid ? "herokuapp.com" : "forums.swift.org"

        let configuration = TNConfiguration()
        guard let certUrlPath = Bundle.main.path(forResource: certificateName, ofType: "cer") else {
            return
        }
        configuration.certificatePaths = [certUrlPath]

        responseString = "fetching..."

        TNRouter<CityRoute>()
            .request(for: .pinning(configuration: configuration))
            .start(responseType: Data.self, onSuccess: { response in
                responseString = response.toJSONString() ?? ""
        }, onFailure: { error, _ in
            responseString = error.localizedDescription ?? ""
        })
    }
}
