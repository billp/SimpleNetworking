//
//  ContentView.swift
//  Shared
//
//  Created by Vasilis Panagiotopoulos on 30/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import SwiftUI

struct DemoApp: Identifiable {
    var id = UUID()
    var name: String
    var description: String
}

struct DemoAppRow: View {
    var app: DemoApp

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(app.name).font(.title3)
            Text(app.description).font(.callout)
        }
    }
}

struct ContentView: View {
    var body: some View {

        let apps = [
            DemoApp(
                name: "City Grid",
                description: "TNRequest + Codables"
            ),
            DemoApp(
                name: "City Grid - Mock Data ",
                description: "TNRequest + Codables + Mock Data"
            ),
            DemoApp(
                name: "Certificate Pinning",
                description: "Man-in-the-middle attack prevention"
            ),
            DemoApp(
                name: "Middlewares",
                description: "Adds encryption layer"
            ),
            DemoApp(
                name: "File Uploader",
                description: "Upload files with progress"
            ),
            DemoApp(
                name: "File Downloader",
                description: "Download files with progress"
            ),
        ]

        NavigationView {
            List(apps) { app in
                NavigationLink(destination: Text("")) {
                    DemoAppRow(app: app)
                }
            }
            .navigationTitle(Text("TermiNetwork Examples"))
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
