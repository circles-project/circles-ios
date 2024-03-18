//
//  CirclesAppDelegate.swift
//  Circles
//
//  Created by Charles Wright on 8/2/23.
//

import Foundation
import Matrix

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
    // > Asks the delegate to process the user’s response to a delivered notification.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) async -> UIBackgroundFetchResult {
        // FIXME
        let keys = userInfo.keys.compactMap { $0 as? String }
        print("DELEGATE\tdidReceiveRemoteNotification!  \(keys.count) keys: \(keys)")
        return .noData
    }
    
}

#else

class CirclesAppDelegate: NSObject {
    // FIXME: Fill this in for MacOS
}

#endif

// https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate
// > Use the methods of the UNUserNotificationCenterDelegate protocol to handle user-selected actions from notifications, and to process notifications that arrive when your app is running in the foreground. After implementing these methods in an object, assign that object to the delegate property of the shared UNUserNotificationCenter object. The user notification center object calls the methods of your delegate at appropriate times.
extension CirclesAppDelegate: UNUserNotificationCenterDelegate {
    
    // https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/usernotificationcenter(_:willpresent:withcompletionhandler:)
    // > Asks the delegate how to handle a notification that arrived while the app was running in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("DELEGATE:\twillPresent user notification")
        
        let info = notification.request.content.userInfo
        guard let eventId = info["event_id"] as? EventId,
              let roomIdString = notification.request.content.userInfo["room_id"] as? String,
              let roomId = RoomId(roomIdString)
        else {
            print("DELEGATE\tCouldn't find event_id and room_id in notification")
            completionHandler([]) // Docs: "Specify UNNotificationPresentationOptionNone to silence the notification completely."  But in Swift, the equivalent is just `[]`.
            return
        }
        
        // TODO: Check that the room is one of ours
        //       The user may be logged in simultaneously to Circles and to a chat app like Element
        //       We don't want to display notifications for chat rooms in Circles, if we can help it.
        
        // FIXME: For now, just don't show anything
        completionHandler([])
        return
    }
    
    // https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/usernotificationcenter(_:didreceive:withcompletionhandler:)
    // > Asks the delegate to process the user’s response to a delivered notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        print("DELEGATE\tdidReceive user notification!  Title = [\(title)]  Body = [\(body)]")
        
        // FIXME: If the room is one of ours, then we should programmatically navigate to it
        
        completionHandler()
    }
    
}
