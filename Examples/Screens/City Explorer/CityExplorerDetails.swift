//
//  CityExplorerDetails.swift
//  TermiNetworkExamples (iOS)
//
//  Created by Vasilis Panagiotopoulos on 6/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import SwiftUI
import TermiNetwork

struct CityExplorerDetails: View {
    @State var activeRequest: TNRequest?
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
        activeRequest = TNRouter<CityRoute>()
            .request(for: .city(id: city.cityID))
            .start(transformer: CityTransformer.self, onSuccess: { city in
                self.city = city
                self.cityFetched = true
            }, onFailure: { (error, _) in
                switch error {
                case .canceled:
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
            .padding([.leading, .trailing, .bottom], 20)
        }
    }

    var thumbView: AnyView {
        AnyView(TNImage(with: TNRouter<CityRoute>().request(for: .image(city: city)),
                        resize: CGSize(width: imageWidth * UIScreen.main.scale,
                                       height: imageHeight * UIScreen.main.scale))
                    .aspectRatio(contentMode: .fill))
    }
}
