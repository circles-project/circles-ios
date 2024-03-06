//
//  CirclesAppDelegate.swift
//  Circles
//
//  Created by Charles Wright on 8/2/23.
//

import Foundation

var apnDeviceToken: Data?

#if os(macOS)

#else

import UIKit

class CirclesAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("DELEGATE\tRegistering for remote notifications")
        UIApplication.shared.registerForRemoteNotifications()
        print("DELEGATE\tDone registering for remote notifications")
        return true
    }


    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken
                    deviceToken: Data) {
        // Send device token to server -- Or, more likely, save it somewhere so we can use it later
        print("DELEGATE\tGot APNs device token for notifications")
        apnDeviceToken = deviceToken
    }


    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // Try again later.
        print("DELEGATE\tFailed to register for remote notifications")
    }

}

#endif
