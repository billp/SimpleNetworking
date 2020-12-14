//
//  DemoNavigation.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 6/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import SwiftUI

struct DemoApp: Identifiable  {
    var id = UUID()
    var name: String
    var description: String
    var destination: AnyView

    static var Apps: [DemoApp] {
        [
           DemoApp(
               name: "City Explorer",
               description: "Router, Transformers, Codables",
               destination: AnyView(CityExplorerView())
           ),
           DemoApp(
               name: "City Explorer - Offline Mode",
               description: "Router, Transformers, Codables, Mock Data",
               destination: AnyView(CityExplorerView(usesMockData: true))
           ),
           DemoApp(
               name: "Certificate Pinning",
               description: "Man-in-the-middle attack prevention",
               destination: AnyView(CertificatePinningView())
           ),
           DemoApp(
               name: "Encrypted Communication",
               description: "Crypto Middleware",
               destination: AnyView(EncryptedCommunicationView())
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
    }
}
