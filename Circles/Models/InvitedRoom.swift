//
//  InvitedRoom.swift
//
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation
import UIKit

class InvitedRoom: ObservableObject {
    var matrix: MatrixSession
    
    let roomId: RoomId
    let type: String?
    let version: String
    let predecessorRoomId: RoomId?
    
    let encrypted: Bool
    
    let creator: UserId
    let sender: UserId
    
    var name: String?
    var topic: String?
    var avatarUrl: String?
    @Published var avatar: UIImage?
    
    var members: [UserId]
    
    private var stateEventsCache: [MatrixEventType: [StrippedStateEvent]]  // From /sync
    
    init(matrix: MatrixSession, roomId: RoomId, stateEvents: [StrippedStateEvent]) throws {

        self.matrix = matrix
        self.roomId = roomId
        
        self.members = []
        self.stateEventsCache = [:]
        
        var type: String?
        var version: String?
        var creator: UserId?
        var sender: UserId?
        var predecessor: RoomId?
        var encryption: StrippedStateEvent?
        
        for event in stateEvents {
            
            if stateEventsCache[event.type] == nil {
                stateEventsCache[event.type] = []
            }
            stateEventsCache[event.type]?.append(event)
                        
            switch event.type {
            case .mRoomCreate:
                guard let content = event.content as? CreateContent
                else {
                    let msg = "Couldn't understand room creation event"
                    throw Matrix.Error(msg)
                }
                type = content.type
                version = content.roomVersion
                creator = event.sender
                predecessor = content.predecessor.roomId
            case .mRoomName:
                guard let content = event.content as? RoomNameContent
                else {
                    let msg = "Couldn't parse room name event"
                    print(msg)
                    throw Matrix.Error(msg)
                }
                self.name = content.name
            case .mRoomAvatar:
                guard let content = event.content as? RoomAvatarContent
                else {
                    let msg = "Couldn't parse room avatar event"
                    throw Matrix.Error(msg)
                }
                self.avatarUrl = content.url
            case .mRoomTopic:
                guard let content = event.content as? RoomTopicContent
                else {
                    let msg = "Couldn't parse room topic event"
                    print(msg)
                    throw Matrix.Error(msg)
                }
                self.topic = content.topic
            case .mRoomMember:
                guard let content = event.content as? RoomMemberContent,
                      let memberUserId = UserId(event.stateKey)
                else {
                    let msg = "Couldn't parse room member event"
                    print(msg)
                    throw Matrix.Error(msg)
                }
                
                if memberUserId == matrix.creds.userId
                    && content.membership == .invite {
                    // This is the event that invited us!
                    sender = event.sender
                } else if content.membership == .join {
                    // This is somebody else in the room
                    self.members.append(memberUserId)
                }
            case .mRoomEncryption:
                encryption = event
            default:
                // Do nothing
                continue
            }
        }
        
        guard let t = type,
              let v = version,
              let c = creator,
              let p = predecessor
        else {
            let msg = "Could not find room creation event"
            print(msg)
            throw Matrix.Error(msg)

        }

        self.type = t
        self.version = v
        self.creator = c
        self.predecessorRoomId = p
        
        guard let s = sender
        else {
            let msg = "Could not find room invite event"
            print(msg)
            throw Matrix.Error(msg)
        }
        
        self.sender = s
        
        if encryption != nil {
            self.encrypted = true
        } else {
            self.encrypted = false
        }
    }
    
    func join(reason: String? = nil) async throws {
        try await matrix.join(roomId: roomId, reason: reason)
    }
    
    func getAvatarImage() async throws {
        guard let url = avatarUrl,
              let mxc = MXC(url)
        else {
            return
        }
        
        let data = try await matrix.downloadData(mxc: mxc)
        let image = UIImage(data: data)
        
        await MainActor.run {
            self.avatar = image
        }
    }
}
