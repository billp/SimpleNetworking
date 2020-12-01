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
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/).onAppear(perform: loadCities)
    }

    func loadCities() {
        let router = TNRouter<CityRoute>()
        router.request(for: .cities).start(responseType: Cities.self) { cities in
            
        } onFailure: { (error, _) in

        }

    }
}

struct CityView_Previews: PreviewProvider {
    static var previews: some View {
        CityView()
    }
}
