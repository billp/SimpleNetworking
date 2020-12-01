//
//  AppDelegate.swift
//  TermiNetwork
//
//  Created by Vasilis Panagiotopoulos on 1/12/20.
//  Copyright © 2020 Bill Panagiotopoulos. All rights reserved.
//

import Foundation
import UIKit
import TermiNetwork

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                        launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        TNEnvironment.set(Environment.heroku)
        return true
    }
}
