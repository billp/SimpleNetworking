// CityExplorerDetails.swift
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
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import SwiftUI
import TermiNetwork

struct CityExplorerDetails: View {
    @State var activeRequest: Request?
    @State var city: City
    @State var errorMessage: String?
    @State var cityFetched: Bool = false

    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .accentColor(.red)
                    .font(.caption)
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            } else if !cityFetched {
                ProgressView()
            } else {
                GeometryReader { geometry in
                    CityDetailsEntry(city: city,
                                     imageWidth: geometry.size.width,
                                     imageHeight: 300)
                }
            }
        }
        .navigationTitle(city.name)
        .onAppear(perform: loadCity)
        .onDisappear(perform: activeRequest?.cancel)
    }

    func loadCity() {
        activeRequest = Router<CityRoute>()
            .request(for: .city(id: city.cityID))
            .start(transformer: CityTransformer.self, onSuccess: { city in
                self.city = city
                self.cityFetched = true
            }, onFailure: { (error, _) in
                switch error {
                case .cancelled:
                    break
                default:
                    self.errorMessage = error.localizedDescription
                }
            })
    }
}

struct CityDetailsEntry: View {
    var city: City
    var imageWidth: CGFloat
    var imageHeight: CGFloat

    var body: some View {
        ScrollView {
            VStack {
                Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0)
                    .overlay(thumbView)
                    .cornerRadius(10)
                    .frame(height: imageHeight)
                Text(city.description ?? "")
                    .font(.body)
            }
            .padding([.leading, .trailing, .bottom, .top], 20)
        }
    }

    var thumbView: AnyView {
        AnyView(TermiNetwork.Image(withRequest: Router<CityRoute>().request(for: .image(city: city)),
                                   resize: CGSize(width: imageWidth * UIScreen.main.scale,
                                              height: imageHeight * UIScreen.main.scale))
                               .aspectRatio(contentMode: .fill))
    }
}
