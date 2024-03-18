//
//  NotificationService.swift
//  NSE
//
//  Created by Charles Wright on 3/8/24.
//

import UserNotifications
import os
import Matrix

struct NotificationError: Error {
    var msg: String
    
    init(_ msg: String) {
        self.msg = msg
    }
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private var task: Task<Void,Error>?
    private var store: DataStore?
    private var logger: os.Logger
    
    override init() {
        self.logger = os.Logger(subsystem: "NSE", category: "nse")
    }
    
    private func loadCredentials() throws -> Matrix.Credentials? {
        logger.debug("Looking for credentials")
        
        guard let defaults = UserDefaults(suiteName: CIRCLES_APP_GROUP_NAME)
        else {
            logger.error("Couldn't access defaults for Circles")
            return nil
        }
        
        guard let uid = defaults.string(forKey: "user_id"),
              let userId = UserId(uid)
        else {
            logger.error("Couldn't load user id")
            return nil
        }
        
        logger.debug("Loading credentials for \(userId.stringValue)")
        return try? Matrix.Credentials.load(for: userId, defaults: defaults)
    }
    
    private func getDataStore(userId: UserId) async throws -> DataStore {
        if let store = self.store {
            return store
        } else {
            let store = try await GRDBDataStore(userId: userId, type: .persistent(preserve: true))
            self.store = store
            return store
        }
    }
    
    private func writeContentWithoutEvent(request: UNNotificationRequest,
                                         content: UNMutableNotificationContent,
                                         client: Matrix.Client,
                                         eventId: EventId,
                                         roomId: RoomId
    ) async throws {
        logger.debug("Fetching room summary for \(roomId)")
        guard let summary = try? await client.getRoomSummary(roomId: roomId)
        else {
            logger.error("Failed to fetch room summary for \(roomId)")
            fallback(content)
            return
        }
        logger.debug("Got room summary for \(roomId)")

        if summary.membership == .invite {
            content.title = "New Invitation"
            switch summary.roomType {
            case ROOM_TYPE_CIRCLE:
                content.body = "Invited to follow \(summary.name ?? "a new timeline")"
            case ROOM_TYPE_GROUP:
                content.body = "Invited to join \(summary.name ?? "a new group")"
            case ROOM_TYPE_PHOTOS:
                content.body = "Invited to share photos in \(summary.name ?? "a new gallery")"
            case ROOM_TYPE_PROFILE:
                content.body = "Invited to connect"
            default:
                content.subtitle = ""
            }
        } else if summary.membership == .leave {
            content.title = "Access Removed"
            if let name = summary.name {
                content.subtitle = "You have left \(name)"
            }
        } else if summary.membership == .ban {
            content.title = "Access Removed"
            if let name = summary.name {
                content.subtitle = "You have been banned from \(name)"
            }
        }
        self.contentHandler?(content)
    }
    
    private func fallback(_ content: UNMutableNotificationContent) {
        content.title = "Circles"
        content.subtitle = "New Post"
        self.contentHandler?(content)
    }
    
    /*
    // Based on code from ElementX iOS
    // FIXME: This doesn't really discard the notification.  It still shows with the default content from the server.
    private func discard(_ request: UNNotificationRequest) {
        logger.debug("Discarding")
        
        let content = UNMutableNotificationContent()
        
        if let unreadCount = request.content.userInfo["unread_count"] as? Int {
            content.badge = NSNumber(value: unreadCount)
        }

        self.contentHandler?(content)
    }
    */
    

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        logger.debug("didReceive")
                        
        guard let bestAttemptContent = bestAttemptContent
        else {
            logger.error("Failed to make mutable copy of the request content")
            return
        }
        logger.debug("Copied request content")
        
        
        guard let eventId = request.content.userInfo["event_id"] as? EventId,
              let roomIdString = request.content.userInfo["room_id"] as? String,
              let roomId = RoomId(roomIdString)
        else {
            logger.error("Failed to get event_id and room_id")
            fallback(bestAttemptContent)
            return
        }
        logger.debug("Found event id \(eventId) and room id \(roomId.stringValue)")

        guard let creds = try? loadCredentials()
        else {
            logger.error("Failed to load credentials")
            fallback(bestAttemptContent)
            return
        }
        logger.debug("Got creds for user id \(creds.userId.stringValue)")
        
        self.task = Task {
            
            guard let defaults = UserDefaults(suiteName: CIRCLES_APP_GROUP_NAME)
            else {
                logger.error("Failed to get defaults for Circles app group")
                fallback(bestAttemptContent)
                return
            }
            
            let client = try await Matrix.Client(creds: creds, defaults: defaults)
            
            
            guard let event = try? await client.getEvent(eventId, in: roomId)
            else {
                logger.warning("Failed to fetch event \(eventId)")
                try await writeContentWithoutEvent(request: request, content: bestAttemptContent, client: client, eventId: eventId, roomId: roomId)
                return
            }
            
            //let store = try await getDataStore(userId: creds.userId)
            
            let roomDisplayName = try await client.getRoomName(roomId: roomId)
            let senderDisplayName = try await client.getDisplayName(userId: event.sender)
            
            bestAttemptContent.title = senderDisplayName ?? event.sender.username
            
            guard let createContent = try await client.getRoomState(roomId: roomId, eventType: M_ROOM_CREATE) as? RoomCreateContent
            else {
                logger.error("Failed to get room creation info")
                fallback(bestAttemptContent)
                return
            }
            
            guard let roomType = createContent.type
            else {
                logger.warning("Room has no type -- must not be one of ours")
                fallback(bestAttemptContent)
                return
            }
            logger.debug("Room type is \(roomType)")
            
            switch roomType {

            case ROOM_TYPE_CIRCLE:
                
                if let roomName = roomDisplayName {
                    bestAttemptContent.body = "Posted to \(roomName)"
                } else if createContent.creator == event.sender {
                    bestAttemptContent.body = "Posted to their timeline"
                } else if let owner = createContent.creator {
                    if let ownerDisplayName = try await client.getDisplayName(userId: owner) {
                        bestAttemptContent.body = "Posted to \(ownerDisplayName)'s timeline"
                    } else {
                        bestAttemptContent.body = "Posted to \(owner.username)'s timeline"
                    }
                } else {
                    bestAttemptContent.body = "Posted to a timeline"
                }
                
            case ROOM_TYPE_GROUP:
                if let roomName = roomDisplayName {
                    bestAttemptContent.body = "Posted in group \(roomName)"
                } else {
                    bestAttemptContent.body = "Posted in a group"
                }
                
            case ROOM_TYPE_PHOTOS:
                if let roomName = roomDisplayName {
                    bestAttemptContent.body = "Posted to \(roomName)"
                } else if createContent.creator == event.sender {
                    bestAttemptContent.body = "Posted to their gallery"
                } else if let owner = createContent.creator {
                    if let ownerDisplayName = try await client.getDisplayName(userId: owner) {
                        bestAttemptContent.body = "Posted to \(ownerDisplayName)'s gallery"
                    } else {
                        bestAttemptContent.body = "Posted to \(owner.username)'s gallery"
                    }
                } else {
                    bestAttemptContent.body = "Posted to a photo gallery"
                }

            default:
                bestAttemptContent.body = "New Post"
            }
            
            contentHandler(bestAttemptContent)
            
        } // End task

    }
    
    override func serviceExtensionTimeWillExpire() {
        logger.debug("serviceExtensionTimeWillExpire")
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent
        {
            contentHandler(bestAttemptContent)
        }
    }

}
