//
//  StateEventView.swift
//  Circles
//
//  Created by Charles Wright on 4/11/23.
//

import Foundation
import SwiftUI
import Matrix

struct StateEventView: View {
    var message: Matrix.Message
    var roomType: String = "room"
    
    var body: some View {
        VStack {
            let sender = message.sender.displayName ?? "\(message.sender.userId)"
            switch message.type {
            case M_ROOM_CREATE:
                Text("*\(roomType.capitalized) created by \(sender)*")
                
            case M_ROOM_AVATAR:
                Text("*\(sender) set a new cover image*")
                
            case M_ROOM_NAME:
                Text("*\(sender) set the \(roomType) name*")
                
            case M_ROOM_TOPIC:
                Text("*\(sender) set the \(roomType) topic*")
                
            case M_ROOM_MEMBER:
                if let content = message.content as? RoomMemberContent
                {
                    switch content.membership {
                    case .invite:
                        Text("*\(sender) invited \(message.stateKey ?? "ERROR Unknown user")*")
                    case .ban:
                        Text("*\(sender) banned \(message.stateKey ?? "ERROR Unknown user")*")
                    case .join:
                        if message.sender.userId.description == message.stateKey {
                            Text("*\(sender) joined*")
                        } else if let otherUser = message.stateKey {
                            Text("*\(sender) added \(otherUser)*")
                        } else {
                            Text("*\(sender) updated their public profile*")
                        }
                    case .knock:
                        Text("*\(sender) knocked*")
                    case .leave:
                        if message.sender.userId.description == message.stateKey {
                            Text("*\(sender) left*")
                        } else {
                            Text("*\(sender) kicked \(message.stateKey ?? "ERROR Unknown user")*")
                        }
                    }
                } else {
                    Text("*\(sender) updated the \(roomType) state*")
                }
            case M_ROOM_ENCRYPTION:
                Text("*\(sender) set the room encryption parameters*")
                
            default:
                Text("*\(sender) updated the \(roomType) state (\(message.type))*")
            }
        }
        .font(.caption)
        .padding(2)
    }
}
