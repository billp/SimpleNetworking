//
//  CityExplorerView.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 30/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import SwiftUI
import TermiNetwork
import Combine

struct CityExplorerView: View {
    var usesMockData: Bool = false

    @State var cities: [City] = []
    @State var request: TNRequest?
    @State var errorMessage: String?
    @State var activeRequest: TNRequest?

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
        TNEnvironment.current.configuration?.mockDataEnabled = usesMockData

        activeRequest = TNRouter<CityRoute>()
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
        TNEnvironment.current.configuration?.mockDataEnabled = false
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
        let request = TNRouter<CityRoute>().request(for: .thumb(city: city))
        return AnyView(
            TNImage(with: request, resize: CGSize(width: thumbWidth * UIScreen.main.scale,
                                                  height: thumbHeight * UIScreen.main.scale))
                .aspectRatio(contentMode: .fill))
    }
}

struct CityExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        CityExplorerView()
    }
}