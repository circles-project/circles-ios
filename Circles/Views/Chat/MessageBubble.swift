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
        HStack(alignment: .bottom) {
            
            let fromMe = message.sender == message.room.session.me
            
            if fromMe {
                Spacer()
            } else {
                avatar
            }
            
            let alignment: HorizontalAlignment = fromMe ? .trailing : .leading
            
            VStack(alignment: alignment) {
                if !fromMe {
                    UserNameView(user: message.sender)
                        .font(
                            Font.custom("Inter", size: 12)
                                .weight(.medium)
                        )
                        .foregroundColor(Color.greyCool800)
                }
                
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
            }
            
            if !fromMe {
                Spacer()
            }
        }
    }
}


