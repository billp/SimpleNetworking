//
//  CityExplorerView.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 30/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import SwiftUI
import TermiNetwork

struct CityExplorerView: View {
    @State var router = TNRouter<CityRoute>()
    @State var cities: [City] = []
    @State var request: TNRequest?

    var body: some View {
        VStack {
            if cities.count == 0 {
                ProgressView()
            } else {
                List(cities, id: \.id) { city in
                    CityRow(city: city,
                            thumbWidth: 100,
                            thumbHeight: 100)
                }
            }
        }
        .navigationTitle("City Grid")
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
    }

    func onAppear() {
        loadCities()
    }
    func onDisappear() {
        request?.cancel()
    }

    func loadCities() {
        request = router.request(for: .cities).start(transformer: CitiesTransformer()) { cities in
            self.cities = cities + cities + cities
        }
    }
}

struct CityRow: View {
    var city: City
    var thumbWidth: CGFloat
    var thumbHeight: CGFloat

    var body: some View {
        NavigationLink(destination: Text("test")) {
            Color(.sRGB, red: 0.922, green: 0.922, blue: 0.922, opacity: 1.0)
                .frame(width: thumbWidth, height: thumbHeight)
                .overlay(
                    TNImage(withUrl: TNEnvironment.current.stringUrl + city.thumb,
                            resize: CGSize(width: thumbWidth * UIScreen.main.scale,
                                           height: thumbHeight * UIScreen.main.scale))
                        .aspectRatio(contentMode: .fill)
                    )
                .cornerRadius(10)
            Text(city.name).font(.headline)
        }
    }
}


struct CityExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        CityExplorerView()
    }
}
