// CityExplorerView.swift
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

import SwiftUI
import TermiNetwork
import Combine

struct CityExplorerView: View {
    var usesMockData: Bool = false

    @State var cities: [City] = []
    @State var request: Request?
    @State var errorMessage: String?
    @State var activeRequest: Request?

    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .accentColor(.red)
                    .font(.caption)
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            } else if cities.count == 0 {
                ProgressView()
            } else {
                List(cities, id: \.id) { city in
                    CityRow(city: city,
                            thumbWidth: 100,
                            thumbHeight: 100)
                }
            }
        }
        .navigationTitle("City Explorer")
        .onAppear(perform: loadCities)
        .onDisappear(perform: onDisappear)
    }

    func loadCities() {
        Environment.current.configuration?.mockDataEnabled = usesMockData

        activeRequest = Router<CityRoute>()
            .request(for: .cities)
            .start(transformer: CitiesTransformer.self,
                   onSuccess: { cities in
            self.cities = cities
        }, onFailure: { (error, _) in
            switch error {
            case .cancelled:
                break
            default:
                self.errorMessage = error.localizedDescription
            }
        })
    }

    func onDisappear() {
        activeRequest?.cancel()
        Environment.current.configuration?.mockDataEnabled = false
    }
}

struct CityRow: View {
    var city: City
    var thumbWidth: CGFloat
    var thumbHeight: CGFloat

    var body: some View {
        NavigationLink(destination: CityExplorerDetails(city: self.city)) {
            Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0)
                .frame(width: thumbWidth, height: thumbHeight)
                .overlay(thumbView)
                .cornerRadius(10)
            Text(city.name).font(.headline)
        }
    }

    var thumbView: AnyView {
        let request = Router<CityRoute>().request(for: .thumb(city: city))
        return AnyView(
            Image(with: request, resize: CGSize(width: thumbWidth * UIScreen.main.scale,
                                                  height: thumbHeight * UIScreen.main.scale))
                .aspectRatio(contentMode: .fill))
    }
}
