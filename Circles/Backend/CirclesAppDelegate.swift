//
//  CirclesAppDelegate.swift
//  Circles
//
//  Created by Charles Wright on 8/2/23.
//

import Foundation

var apnDeviceToken: Data?

#if canImport(UIKit)

import UIKit

class CirclesAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.
        print("DELEGATE\tRegistering for remote notifications")
        UIApplication.shared.registerForRemoteNotifications()
        print("DELEGATE\tDone registering for remote notifications")
        
        // Register our delegate for user notifications
        print("DELEGATE\tSetting self as the user notification center delegate")
        UNUserNotificationCenter.current().delegate = self
        
        
        let registered = UIApplication.shared.isRegisteredForRemoteNotifications
        print("DELEGATE\tRegistered for remote notifications?  \(registered)")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings {
            switch $0.authorizationStatus {
            case .notDetermined:
                print("DELEGATE\tNotifications authorization not determined")
            case .denied:
                print("DELEGATE\tNotifications authorization denied")
            case .authorized:
                print("DELEGATE\tNotifications authorization authorized")
            case .provisional:
                print("DELEGATE\tNotifications authorization provisional")
            case .ephemeral:
                print("DELEGATE\tNotifications authorization ephemeral")
            default:
                print("DELEGATE\tNotifications authorization is something unknown")
            }
        }
        
        print("DELEGATE\tDone with didFinishLaunching...")
        return true
    }


    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken
                    deviceToken: Data
    ) {
        // Send device token to server -- Or, more likely, save it somewhere so we can use it later
        print("DELEGATE\tGot APNs device token for notifications: \(deviceToken.hexString)")
        apnDeviceToken = deviceToken
    }


    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error
    ) {
        // Try again later.
        print("DELEGATE\tFailed to register for remote notifications")
    }
    
    // Tells the app that a remote notification arrived that indicates there is data to be fetched.
    // Called when the app is either in the foreground or background
    // https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) async -> UIBackgroundFetchResult {
        // FIXME
        print("DELEGATE\tdidReceiveRemoteNotification!")
        return .noData
    }
    
}

#else

class CirclesAppDelegate: NSObject {
    // FIXME: Fill this in for MacOS
}

#endif

// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate
// Following instructions from https://designcode.io/swiftui-advanced-handbook-push-notifications-part-2
extension CirclesAppDelegate: UNUserNotificationCenterDelegate {
    
    /*
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // FIXME: TODO: Actually implement this one
    }
    */
    
    // Handle incoming notifications
    // Somehow this doesn't get called when the above didReceiveRemoteNotification fires...
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        print("DELEGATE\tdidReceive user notification!  Title = [\(title)]  Body = [\(body)]")
        completionHandler()
    }
    
}
