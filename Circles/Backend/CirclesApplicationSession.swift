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
    
    private(set) public static var current: CirclesApplicationSession?
    
    var logger: os.Logger
    
    var store: CirclesStore
    var matrix: Matrix.Session

    // IDEA: We could store any Circles-specific configuration info in our account data in the root "Circles" space room
    var config: CirclesConfigContentV2
    
    var timelines: TimelineSpace   // Our top-level timelines space contains the spaces for each of our timelines
    var groups: ContainerRoom<GroupRoom>        // Groups space contains the individual rooms for each of our groups
    var galleries: ContainerRoom<GalleryRoom>   // Galleries space contains the individual rooms for each of our galleries
    var people: ContainerRoom<PersonRoom>       // People space contains the space rooms for each of our contacts
    var profile: ContainerRoom<Matrix.Room>     // Our profile space contains the "wall" rooms for each circle that we "publish" to our connections
    
    
    @Published var viewState = ViewState()      // The ViewState encapsulates all the top-level UI state for the app when we're logged in with this active application session
    public class ViewState: ObservableObject {
        enum Tab: String {
            case circles
            case people
            case groups
            case chat
            case photos
            case settings
        }
        @Published var tab: Tab = .circles
        @Published var knockRoomId: RoomId?
        
        @Published var selectedGroupId: RoomId?
        @Published var selectedTimelineId: RoomId?
        @Published var selectedGalleryId: RoomId?
        @Published var selectedChatId: RoomId?
        
        @MainActor
        func navigate(tab: Tab, selected: RoomId?) {
            print("VIEWSTATE Navigating to tab \(tab) and room \(selected?.stringValue ?? "(none)")")
            switch tab {
            case .circles:
                self.tab = .circles
                self.selectedTimelineId = selected
            case .people:
                self.tab = .people
                // FIXME: Set a selected profile roomId
            case .groups:
                self.tab = .groups
                self.selectedGroupId = selected
            case .chat:
                self.tab = .chat
                self.selectedChatId = selected
            case .photos:
                self.tab = .photos
                self.selectedGalleryId = selected
            case .settings:
                self.tab = .settings
            }
        }
        
        @MainActor
        func knock(roomId: RoomId) {
            self.knockRoomId = roomId
        }
    }
    
    public func roomIsKnown(roomId: RoomId) -> Bool {
        // Is the given room one of our various content rooms?
        if self.groups.rooms[roomId] != nil {
            return true
        }
        if self.galleries.rooms[roomId] != nil {
            return true
        }
        if self.people.rooms[roomId] != nil {
            return true
        }
        if self.timelines.rooms.values.contains(where: { room in
            room.roomId == roomId
        }) {
            return true
        }
        
        // Not a content room. Maybe it's a space in our hierarchy?
        if self.groups.roomId == roomId || self.galleries.roomId == roomId || self.people.roomId == roomId || self.timelines.roomId == roomId || self.config.root == roomId {
            return true
        }
        
        // Maybe it's a room that we've been invited to, but we are not yet a member?
        if let _ = self.matrix.invitations[roomId] { // let invitedRoom
            return true
        }
        
        // Otherwise I guess we don't know about this one
        return false
    }
    
    public func roomIsInvited(roomId: RoomId) -> Bool {
        self.matrix.invitations[roomId] != nil
    }
        
    public func onOpenURL(url: URL) {
        guard let host = url.host()
        else {
            print("DEEPLINK Not processing URL \(url) -- No host")
            return
        }
        let components = url.pathComponents
        
        print("DEEPLINK URL: Host = \(host)")
        print("DEEPLINK URL: Path = \(components)")
        
        guard url.pathComponents.count >= 3,
              url.pathComponents[0] == "/",
              let roomId = RoomId(url.pathComponents[2])
        else {
            print("DEEPLINK Not processing URL \(url) -- No first path component")
            return
        }
        
        guard let _ = self.matrix.rooms[roomId] // let room
        else {
            print("DEEPLINK Not in room \(roomId) -- Knocking on it")
            self.viewState.knockRoomId = roomId
            return
        }
        
        let prefix = url.pathComponents[1]
        switch prefix {
        
        case "timeline":
            print("DEEPLINK Url is for a circle timeline")
            
            // Do we have a Circle space that contains the given room?
            if let matchingTimeline = self.timelines.rooms[roomId] {
                print("DEEPLINKS TIMELINES Setting selected timeline to \(matchingTimeline.name ?? matchingTimeline.roomId.stringValue)")
                print("DEEPLINK Setting tab to Circles")
                self.viewState.tab = .circles
                self.viewState.selectedTimelineId = matchingTimeline.roomId
                return
            } else {
                print("DEEPLINKS CIRCLES Room \(roomId) is not one of ours")
            }
        
        case "profile":
            print("DEEPLINK Setting tab to People")
            self.viewState.tab = .people
            // FIXME: Set the selected profile to view the friend's info
            return
        
        case "group":
            print("DEEPLINK Url is for a group")
            if let _ = self.groups.rooms[roomId] { // let matchingGroup
                print("DEEPLINK Setting tab to Groups")
                self.viewState.tab = .groups
                self.viewState.selectedGroupId = roomId
                return
            } else {
                print("DEEPLINK Group room is not one of ours")
            }
        
        case "gallery":
            print("DEEPLINK Url is for a photo gallery")
            let enableGalleries = UserDefaults.standard.bool(forKey: DEFAULTS_KEY_ENABLE_GALLERIES)
            if enableGalleries {
                if let _ = self.galleries.rooms[roomId] { // let matchingGallery
                    print("DEEPLINK Setting tab to Photos")
                    self.viewState.tab = .photos
                    self.viewState.selectedGalleryId = roomId
                    return
                } else {
                    print("DEEPLINK Gallery room is not one of ours")
                }
            } else {
                print("DEEPLINK Galleries are not enabled - ignoring")
            }
        
        case "room":
            Task {
                try await navigate(to: roomId)
            }
            return

        default:
            print("DEEPLINK Unknown URL prefix [\(prefix)]")
        }
    }
    
    public func navigate(to roomId: RoomId) async throws {
        // Is this a room that we already know?
        if let room = try? await self.matrix.getRoom(roomId: roomId) {
            // Let's see what type of room it is, and use that to set the selected tab.
            print("NAVIGATE Found room \(room.roomId) with type \(room.type ?? "(none)")")
            
            switch room.type {
            
            case ROOM_TYPE_CIRCLE:
                print("NAVIGATE Room looks like a circle timeline")
                if let timeline = self.timelines.rooms[roomId] {
                    print("NAVIGATE Navigating to timeline \(timeline.name ?? timeline.roomId.stringValue)")
                    await self.viewState.navigate(tab: .circles, selected: timeline.roomId)
                    return
                } else {
                    print("NAVIGATE Circle timeline room is not part of our hierarchy")
                }
                
            case "m.space":
                if let _ = self.people.rooms[roomId] { // let profile
                    await self.viewState.navigate(tab: .people, selected: roomId)
                    return
                } else {
                    print("NAVIGATE (Profile?) Space room is not part of our hierarchy")
                }
                
            case ROOM_TYPE_GROUP:
                print("NAVIGATE Room looks like a group")
                if let group = self.groups.rooms[roomId] {
                    print("NAVIGATE Navigating to group \(group.name ?? group.roomId.stringValue)")
                    await self.viewState.navigate(tab: .groups, selected: roomId)
                    return
                } else {
                    print("NAVIGATE Group room is not part of our hierarchy")
                }
                
            case ROOM_TYPE_PHOTOS:
                if let _ = self.galleries.rooms[roomId] { // let gallery
                    await self.viewState.navigate(tab: .photos, selected: roomId)
                    return
                } else {
                    print("NAVIGATE Gallery room is not part of our hierarchy")
                }
                
            default:
                print("NAVIGATE Room type \(room.type ?? "(none)") doesn't match any of our tabs - doing nothing")
            }
        }
        // The room id is not known to us
        // Do we have an existing invitation to this room?
        else if let invitation = try? await self.matrix.getInvitedRoom(roomId: roomId) {
            switch invitation.type {
            case ROOM_TYPE_CIRCLE:
                await self.viewState.navigate(tab: .circles, selected: nil)
                return
            case ROOM_TYPE_PROFILE:
                await self.viewState.navigate(tab: .people, selected: nil)
                return
            case ROOM_TYPE_GROUP:
                await self.viewState.navigate(tab: .groups, selected: nil)
                return
            case ROOM_TYPE_PHOTOS:
                await self.viewState.navigate(tab: .photos, selected: nil)
            default:
                print("NAVIGATE Can't handle invitation to unknown room type \(invitation.type ?? "(none)")")
            }
        }
        // Maybe we can get its summary?
        else if let summary = try? await self.matrix.getRoomSummary(roomId: roomId) {
            print("NAVIGATE Got room summary")
            // Is this an invitation that we don't have in our session yet?
            if summary.membership == .invite {
                print("NAVIGATE Summary says we're invited")
                switch summary.roomType {
                case ROOM_TYPE_CIRCLE:
                    await self.viewState.navigate(tab: .circles, selected: nil)
                    return
                case ROOM_TYPE_PROFILE:
                    await self.viewState.navigate(tab: .people, selected: nil)
                    return
                case ROOM_TYPE_GROUP:
                    await self.viewState.navigate(tab: .groups, selected: nil)
                    return
                case ROOM_TYPE_PHOTOS:
                    await self.viewState.navigate(tab: .photos, selected: nil)
                default:
                    print("NAVIGATE Can't handle invitation to unknown room type \(summary.roomType ?? "(none)")")
                }
            } else if summary.membership == .leave {
                print("NAVIGATE Summary says we're not in the room")
                // Only thing we can do is knock to request access
                await self.viewState.knock(roomId: roomId)
                return
            } else {
                print("NAVIGATE Summary says we're in state \(summary.membership?.rawValue ?? "(none)") -- Not sure what to do")
            }
            
        }
        // The room is not known to us, and we can't get its summary
        // Not much we can do here
        else {
            print("NAVIGATE Room is unknown and we can't get a summary.  All we can do is knock.")
            await self.viewState.knock(roomId: roomId)
            return
        }
    }
    

    

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
    
    init(store: CirclesStore, matrix: Matrix.Session, config: CirclesConfigContentV2) async throws {
        let logger = Logger(subsystem: "Circles", category: "Session")
        self.logger = logger
        self.store = store
        self.matrix = matrix
        self.config = config
        
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
        guard let galleries = try await matrix.getRoom(roomId: config.galleries, as: ContainerRoom<GalleryRoom>.self)
        else {
            logger.error("Failed to load Galleries space")
            throw CirclesError("Failed to load Galleries space")
        }
        
        logger.debug("Loading Timelines space")
        guard let timelines = try await matrix.getRoom(roomId: config.timelines, as: TimelineSpace.self)
        else {
            logger.error("Failed to load Timelines space")
            throw CirclesError("Failed to load Timelines space")
        }
        
        logger.debug("Loading People space")
        guard let people = try await matrix.getRoom(roomId: config.people, as: ContainerRoom<PersonRoom>.self)
        else {
            logger.error("Failed to load People space")
            throw CirclesError("Failed to load People space")
        }
        
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
        self.timelines = timelines
        self.people = people
        self.profile = profile
        
        // Register ourself as the current singleton object
        Self.current = self
        
        // Initialize the circles / timelines view to display the unified feed by default
        self.viewState.selectedTimelineId = timelines.roomId
        
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
            
            if !timelines.parents.contains(rootRoomId) {
                logger.debug("Adding space parent for Circles space")
                try await matrix.addSpaceParent(rootRoomId, to: timelines.roomId, canonical: true)
            }
            
            if !people.parents.contains(rootRoomId) {
                logger.debug("Adding space parent for People space")
                try await matrix.addSpaceParent(rootRoomId, to: people.roomId, canonical: true)
            }
            
            // Don't add the parent space event to the profile space -- We don't want others to see it
            
            let spaceChildRoomIds = [groups.roomId, galleries.roomId, timelines.roomId, people.roomId, profile.roomId]
            
            for childRoomId in spaceChildRoomIds {
                if !root.children.contains(childRoomId) {
                    logger.debug("Adding child space \(childRoomId, privacy: .public) to Circles root space")
                    try await root.addChild(childRoomId)
                }
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
