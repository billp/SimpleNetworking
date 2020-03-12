//
//  AppDelegate.swift
//  TermiNetwork
//
//  Created by billp.dev@gmail.com on 02/21/2018.
//  Copyright (c) 2018 billp.dev@gmail.com. All rights reserved.
//

import UIKit
import TermiNetwork
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        TNEnvironment.set(Environment.production)
        TNEnvironment.verbose = true

        TNQueue.shared.beforeAllRequestsCallback = {
            SVProgressHUD.show()
        }

        TNQueue.shared.afterAllRequestsCallback = { _ in
            SVProgressHUD.dismiss()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

}
