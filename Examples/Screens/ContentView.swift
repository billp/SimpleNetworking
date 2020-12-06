//
//  ContentView.swift
//  Shared
//
//  Created by Vasilis Panagiotopoulos on 30/11/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import SwiftUI
import Combine

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
        NavigationView {
            List(DemoApp.Apps) { app in
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
