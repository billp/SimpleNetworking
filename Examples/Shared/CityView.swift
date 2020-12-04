//
//  CityView.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 30/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import SwiftUI
import TermiNetwork

struct CityView: View {
    @State var router = TNRouter<CityRoute>()
    @State var cities: [City] = []
    @State var request: TNRequest?

    var body: some View {
        if cities.count == 0 {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }

        List(cities, id: \.id) { city in

            TNImage(withUrl: TNEnvironment.current.description + city.thumb).frame(width: 80, height: 80)
            Text(city.name)
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

struct CityView_Previews: PreviewProvider {
    static var previews: some View {
        CityView()
    }
}
