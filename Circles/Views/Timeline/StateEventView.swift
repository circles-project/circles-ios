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
                        Text("*\(sender) invited \(message.stateKey!)*")
                    case .ban:
                        Text("*\(sender) banned \(message.stateKey!)*")
                    case .join:
                        if message.sender.userId.description == message.stateKey {
                            Text("*\(sender) joined*")
                        } else {
                            Text("*\(sender) added \(message.stateKey!)*")
                        }
                    case .knock:
                        Text("*\(sender) knocked*")
                    case .leave:
                        if message.sender.userId.description == message.stateKey {
                            Text("*\(sender) left*")
                        } else {
                            Text("*\(sender) kicked \(message.stateKey!)*")
                        }
                    }
                } else {
                    Text("*\(sender) updated the \(roomType) state*")
                }
                
                
            default:
                if message.stateKey != nil {
                    Text("*\(sender) updated the \(roomType) state*")
                } else {
                    Text("*\(sender) sent an unknown message (\(message.type))*")
                }
            }
        }
        .font(.caption)
        .padding(2)
    }
}
