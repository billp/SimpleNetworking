//
//  ContentView.swift
//  Shared
//
//  Created by Vasilis Panagiotopoulos on 30/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import SwiftUI

struct DemoApp: Identifiable  {
    var id = UUID()
    var name: String
    var description: String
    var destination: AnyView
}

struct DemoAppRow: View {
    var app: DemoApp

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(app.name).font(.system(size: 18))
            Text(app.description).font(.system(size: 15))
        }
    }
}

struct ContentView: View {
    var body: some View {

        let apps = [
            DemoApp(
                name: "City Grid",
                description: "TNRequest + Codables",
                destination: AnyView(CityView())
            ),
            DemoApp(
                name: "City Grid - Mock Data ",
                description: "TNRequest + Codables + Mock Data",
                destination: AnyView(Text("da"))
            ),
            DemoApp(
                name: "Certificate Pinning",
                description: "Man-in-the-middle attack prevention",
                destination: AnyView(Text("ds"))
            ),
            DemoApp(
                name: "Middlewares",
                description: "Adds encryption layer",
                destination: AnyView(Text(""))
            ),
            DemoApp(
                name: "File Uploader",
                description: "Upload files with progress",
                destination: AnyView(Text(""))
            ),
            DemoApp(
                name: "File Downloader",
                description: "Download files with progress",
                destination: AnyView(Text(""))
            )
        ]

        NavigationView {
            List(apps) { app in
                NavigationLink(destination: app.destination) {
                    DemoAppRow(app: app)
                }
            }
            .navigationTitle(Text("TermiNetwork"))
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
