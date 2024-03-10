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
    private var task: Task<UNNotificationContent,Error>?
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
    
    // FIXME: This doesn't work because Synapse doesn't return a valid event
    /*
    private func getCreateEvent(roomId: RoomId, store: DataStore, client: Matrix.Client) async throws -> ClientEventWithoutRoomId {
        if let event = try? await store.loadState(for: roomId, type: M_ROOM_CREATE, stateKey: "")
        {
            return event
        }
        
        if let event = try? await client.getRoomStateEvent(roomId: roomId, eventType: M_ROOM_CREATE) {
            try await store.saveState(events: [event], in: roomId)
            return event
        }
        
        throw NotificationError("Failed to load room info")
    }
    */

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        logger.debug("didReceive")
        
        logger.debug("Still here")
                
        guard let bestAttemptContent = bestAttemptContent
        else {
            logger.error("NSE: Failed to make mutable copy of the request content")
            return
        }
        logger.debug("NSE: Copied request content")
        
        guard let eventId = request.content.userInfo["event_id"] as? EventId,
              let roomIdString = request.content.userInfo["room_id"] as? String,
              let roomId = RoomId(roomIdString)
        else {
            logger.error("NSE: Failed to get event_id and room_id")
            bestAttemptContent.title = "Notification"
            //contentHandler(bestAttemptContent)
            return
        }
        logger.debug("Found event id \(eventId) and room id \(roomId.stringValue)")
        
        guard let creds = try? loadCredentials()
        else {
            logger.error("NSE: Failed to load credentials")
            bestAttemptContent.title = "Notification"
            //contentHandler(bestAttemptContent)
            return
        }
        logger.debug("NSE: Got creds for user id \(creds.userId.stringValue)")
        
        self.task = Task {
            let client = try await Matrix.Client(creds: creds)
            
            let event = try await client.getEvent(eventId, in: roomId)
            
            //let store = try await getDataStore(userId: creds.userId)
            
            let roomDisplayName = try await client.getRoomName(roomId: roomId)
            let senderDisplayName = try await client.getDisplayName(userId: event.sender)
            
            // Did we just get an invitation?
            if event.type == M_ROOM_MEMBER,
               event.stateKey == creds.userId.stringValue,
               event.sender != creds.userId,
               let content = event.content as? RoomMemberContent
            {
                logger.debug("Event is a membership event")
                // Well, someone else just modified our join state in the room.. we either got invited, or kicked, or banned :P
                switch content.membership {
                case .join:
                    bestAttemptContent.title = "New Invitation"
                    if let roomName = roomDisplayName {
                        bestAttemptContent.subtitle = "\(senderDisplayName ?? event.sender.stringValue) is inviting you to \(roomName)"
                    } else {
                        bestAttemptContent.subtitle = "From \(senderDisplayName ?? event.sender.stringValue)"
                    }
                    contentHandler(bestAttemptContent)
                    return bestAttemptContent
                case .leave:
                    bestAttemptContent.title = "Access Removed"
                    if let roomName = roomDisplayName {
                        bestAttemptContent.subtitle = "\(senderDisplayName ?? event.sender.stringValue) has removed you from \(roomName)"
                    } else {
                        bestAttemptContent.subtitle = "You have been removed by \(senderDisplayName ?? event.sender.stringValue)"
                    }
                    contentHandler(bestAttemptContent)
                    return bestAttemptContent
                case .ban:
                    bestAttemptContent.title = "Access Removed"
                    if let roomName = roomDisplayName {
                        bestAttemptContent.subtitle = "\(senderDisplayName ?? event.sender.stringValue) has banned you from \(roomName)"
                    } else {
                        bestAttemptContent.subtitle = "You have been banned by \(senderDisplayName ?? event.sender.stringValue)"
                    }
                    contentHandler(bestAttemptContent)
                    return bestAttemptContent
                default:
                    // Shouldn't be here but here we are...
                    bestAttemptContent.title = "Access Changed"
                    if let roomName = roomDisplayName {
                        bestAttemptContent.subtitle = "Your access to \(roomName) has changed"
                    } else {
                        bestAttemptContent.subtitle = "Your access has been modified by \(senderDisplayName ?? event.sender.stringValue)"
                    }
                    contentHandler(bestAttemptContent)
                    return bestAttemptContent
                }
            }
            
            logger.debug("Event does not look like a membership event")
            
            guard let createContent = try await client.getRoomState(roomId: roomId, eventType: M_ROOM_CREATE) as? RoomCreateContent,
                  let roomType = createContent.type
            else {
                logger.warning("Could not get room type")
                // Gotta make do the best we can with the info that we have available
                bestAttemptContent.title = "New Post by \(senderDisplayName ?? event.sender.stringValue)"
                contentHandler(bestAttemptContent)
                return bestAttemptContent
            }
            logger.debug("Room type is \(roomType)")
            
            switch roomType {
            case ROOM_TYPE_CIRCLE:
                if let roomName = roomDisplayName {
                    bestAttemptContent.title = "\(senderDisplayName ?? event.sender.stringValue) posted in \(roomName)"
                } else {
                    bestAttemptContent.title = "\(senderDisplayName ?? event.sender.stringValue) sent a new post"
                }
                contentHandler(bestAttemptContent)
                return bestAttemptContent
                
            default:
                bestAttemptContent.title = "New Post by \(senderDisplayName ?? event.sender.stringValue)"
                contentHandler(bestAttemptContent)
                return bestAttemptContent

            }
            
            
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
