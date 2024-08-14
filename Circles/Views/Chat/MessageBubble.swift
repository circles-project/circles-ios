//
//  MessageBubble.swift
//  Circles
//
//  Created by Charles Wright on 8/13/24.
//

import SwiftUI
import Matrix

struct MessageBubble: View {
    @ObservedObject var message: Matrix.Message
    
    @ViewBuilder
    var avatar: some View {
        UserAvatarView(user: message.sender)
            .frame(width: 24, height: 24)
    }
    
    var body: some View {
        VStack {
            if message.type == M_ROOM_MESSAGE ||
                message.type == M_ROOM_ENCRYPTED ||
                message.type == ORG_MATRIX_MSC3381_POLL_START {
                let fromMe = message.sender == message.room.session.me
                
                if let content = message.content as? Matrix.MessageContent {
                    let backgroundColor = fromMe ? Color.accentColor.opacity(0.8) : Color.greyCool400
                    let foregroundColor = fromMe ? Color.greyCool100 : Color.greyCool1100
                    
                    Text(content.body)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .font(
                            Font.custom("Inter", size: 14)
                                .weight(.medium)
                        )
                        .foregroundColor(foregroundColor)
                } else {
                    Text("Error: Failed to decode message")
                        .foregroundColor(.red)
                }
            } else if DebugModel.shared.debugMode && message.stateKey != nil {
                StateEventView(message: message)
            }
        }
    }
}


