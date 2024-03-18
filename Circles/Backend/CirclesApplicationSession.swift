//
//  CirclesSession.swift
//  Circles
//
//  Created by Charles Wright on 6/21/22.
//

import Foundation
import UserNotifications
import Matrix
import os

#if os(macOS)
import AppKit
#else
import UIKit
#endif


class CirclesApplicationSession: ObservableObject {
    var logger: os.Logger
    
    var store: CirclesStore
    var matrix: Matrix.Session

    // IDEA: We could store any Circles-specific configuration info in our account data in the root "Circles" space room
    var config: CirclesConfigContent
    
    var circles: ContainerRoom<CircleSpace>     // Our top-level circles space contains the spaces for each of our circles
    var groups: ContainerRoom<GroupRoom>        // Groups space contains the individual rooms for each of our groups
    var galleries: ContainerRoom<GalleryRoom>   // Galleries space contains the individual rooms for each of our galleries
    var people: ContainerRoom<PersonRoom>       // People space contains the space rooms for each of our contacts
    var profile: ContainerRoom<Matrix.Room>     // Our profile space contains the "wall" rooms for each circle that we "publish" to our connections
    

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Circles Test Notification"
        content.subtitle = "This is only a test"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    
    func setupPushNotifications() async throws {
        
        let center = UNUserNotificationCenter.current()
        
        guard let allowed = try? await center.requestAuthorization(options: [.alert, .sound, .badge]),
              allowed == true
        else {
            logger.error("Notifications: Not allowed by user")
            return
        }

        // Get the APN device token that our AppDelegate received from Apple
        guard let token = apnDeviceToken
        else {
            logger.error("Notifications: No APN device token")
            return
        }
        logger.debug("Notifications: Got APN device token \(token.hexString)")
        
        // Request body based on https://spec.matrix.org/v1.6/client-server-api/#post_matrixclientv3pushersset
        // `data` from https://github.com/matrix-org/sygnal/blob/main/docs/applications.md#ios-applications-beware
        
        let deviceModel = await UIDevice.current.model
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "???"
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let base64Token = token.base64EncodedString()
        logger.debug("Notifications: Delegate's base64 token is \(base64Token)")
        let body = """
        {
            "app_display_name": "Circles iOS \(version)",
            "app_id": "org.futo.circles.ios",
            "data": {
                "url": "https://\(PUSH_GATEWAY_HOSTNAME)/_matrix/push/v1/notify",
                "format": "event_id_only",
                "default_payload": {
                    "aps": {
                        "mutable-content": 1,
                        "content-available": 1,
                        "alert": {"title": "NEW NOTIFICATION"}
                    }
                }
            },
            "device_display_name": "Circles (\(deviceModel))",
            "kind": "http",
            "lang": "\(languageCode)",
            "pushkey": "\(base64Token)"
        }
        """
        
        logger.debug("Notifications: Sending request with body: \(body)")
        
        logger.debug("Notifications: Setting up APN on Matrix homeserver")
        
        let path = "/_matrix/client/v3/pushers/set"
        let (data, response) = try await self.matrix.call(method: "POST", path: path, bodyData: body.data(using: .utf8))
        
        logger.debug("Notifications: Sygnal APN call received \(data.count) bytes of response with status \(response.statusCode)")

    }
    
    init(store: CirclesStore, matrix: Matrix.Session, config: CirclesConfigContent) async throws {
        let logger = Logger(subsystem: "Circles", category: "Session")
        self.logger = logger
        self.store = store
        self.matrix = matrix
        self.config = config
        
        let startTS = Date()

        logger.debug("Loading Matrix spaces")
        
        logger.debug("Loading Groups space")
        let groupsStart = Date()
        guard let groups = try await matrix.getRoom(roomId: config.groups, as: ContainerRoom<GroupRoom>.self)
        else {
            logger.error("Failed to load Groups space")
            throw CirclesError("Failed to load Groups space")
        }
        let groupsEnd = Date()
        let groupsTime = groupsEnd.timeIntervalSince(groupsStart)
        logger.debug("\(groupsTime, privacy: .public) sec to load Groups space")
        
        logger.debug("Loading Galleries space")
        let galleriesStart = Date()
        guard let galleries = try await matrix.getRoom(roomId: config.galleries, as: ContainerRoom<GalleryRoom>.self)
        else {
            logger.error("Failed to load Galleries space")
            throw CirclesError("Failed to load Galleries space")
        }
        let galleriesEnd = Date()
        let galleriesTime = galleriesEnd.timeIntervalSince(galleriesStart)
        logger.debug("\(galleriesTime, privacy: .public) sec to load Galleries space")
        
        logger.debug("Loading Circles space")
        let circlesStart = Date()
        guard let circles = try await matrix.getRoom(roomId: config.circles, as: ContainerRoom<CircleSpace>.self)
        else {
            logger.error("Failed to load Circles space")
            throw CirclesError("Failed to load Circles space")
        }
        let circlesEnd = Date()
        let circlesTime = circlesEnd.timeIntervalSince(circlesStart)
        logger.debug("\(circlesTime, privacy: .public) sec to load Circles space")
        
        logger.debug("Loading People space")
        let peopleStart = Date()
        guard let people = try await matrix.getRoom(roomId: config.people, as: ContainerRoom<PersonRoom>.self)
        else {
            logger.error("Failed to load People space")
            throw CirclesError("Failed to load People space")
        }
        let peopleEnd = Date()
        let peopleTime = peopleEnd.timeIntervalSince(peopleStart)
        logger.debug("\(peopleTime, privacy: .public) sec to load People space")
        
        logger.debug("Loading Profile space")
        let profileStart = Date()
        guard let profile = try await matrix.getRoom(roomId: config.profile, as: ContainerRoom<Matrix.Room>.self)
        else {
            logger.error("Failed to load Profile space")
            throw CirclesError("Failed to load Profile space")
        }
        let profileEnd = Date()
        let profileTime = profileEnd.timeIntervalSince(profileStart)
        logger.debug("\(profileTime, privacy: .public) sec to load Profile space")
                
        self.groups = groups
        self.galleries = galleries
        self.circles = circles
        self.people = people
        self.profile = profile
        
        let endTS = Date()
        
        let totalTime = endTS.timeIntervalSince(startTS)
        logger.debug("\(totalTime, privacy: .public) sec to initialize Circles Session")
        
        Task {
            logger.debug("Verifying Matrix Space relations")
            let rootRoomId = config.root
            
            guard let root = try await matrix.getSpaceRoom(roomId: rootRoomId)
            else {
                logger.error("Failed to get Space room for the Circles root")
                return
            }
            
            for child in root.children {
                logger.debug("Found child space \(child)")
            }
            
            if !groups.parents.contains(rootRoomId) {
                logger.debug("Adding space parent for Groups space")
                try await matrix.addSpaceParent(rootRoomId, to: groups.roomId, canonical: true)
            }
            
            if !galleries.parents.contains(rootRoomId) {
                logger.debug("Adding space parent for Galleries space")
                try await matrix.addSpaceParent(rootRoomId, to: galleries.roomId, canonical: true)
            }
            
            if !circles.parents.contains(rootRoomId) {
                logger.debug("Adding space parent for Circles space")
                try await matrix.addSpaceParent(rootRoomId, to: circles.roomId, canonical: true)
            }
            
            if !people.parents.contains(rootRoomId) {
                logger.debug("Adding space parent for People space")
                try await matrix.addSpaceParent(rootRoomId, to: people.roomId, canonical: true)
            }
            
            // Don't add the parent space event to the profile space -- We don't want others to see it
            
            let spaceChildRoomIds = [groups.roomId, galleries.roomId, circles.roomId, people.roomId, profile.roomId]
            
            for childRoomId in spaceChildRoomIds {
                if !root.children.contains(childRoomId) {
                    logger.debug("Adding child space \(childRoomId, privacy: .public) to Circles root space")
                    try await root.addChild(childRoomId)
                }
            }
            
            // Remove the Shared Circles / My Profile space from My Circles if it's there
            if circles.children.contains(profile.roomId) {
                logger.debug("Removing Shared Circles / Profile space from My Circles")
                try await circles.removeChild(profile.roomId)
            }
            
            logger.debug("Done verifying space relations")
        }
        
        logger.debug("Starting Matrix background sync")
        try await matrix.startBackgroundSync()
        
        logger.debug("Setting up push notifications")
        try await setupPushNotifications()
                
        logger.debug("Finished setting up Circles application session")
    }
    
    func cancelUIA() async throws {
        // Cancel any current Matrix UIA session that we may have
        try await matrix.cancelUIA()
        // And tell any SwiftUI views (eg the main ContentView) that they should re-draw
        await MainActor.run {
            self.objectWillChange.send()
        }
    }

    
    func close() async throws {
        logger.debug("Closing Circles session")
        try await matrix.close()
    }
}
