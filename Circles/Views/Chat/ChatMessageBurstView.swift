//
//  ChatMessageBurstView.swift
//  Circles
//
//  Created by Charles Wright on 8/14/24.
//

import SwiftUI
import Matrix

struct ChatMessageBurstView: View {
    @ObservedObject var burst: Matrix.MessageBurst
    var threaded = false
    
    @ViewBuilder
    var avatar: some View {
        UserAvatarView(user: burst.sender)
            .frame(width: 24, height: 24)
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            
            let fromMe = burst.sender.userId == burst.room.session.me.userId
            
            if fromMe {
                // For whatever reason, using a single Spacer doesn't give the effect that I want.
                // I want to guarantee a minimum amount of empty space, but let the Text next door expand as much as it wants up to that point.
                // The only way to do it seems to be to use one Spacer with a fixed width to occupy the minimum blank space,
                // and then use another Spacer without a frame to provide the flexibility.
                // Doesn't make a ton of sense to me but :shrug: it is what it is.
                
                Spacer()
                    .frame(width: 60)
                Spacer()
            } else {
                avatar
            }
            
            let alignment: HorizontalAlignment = fromMe ? .trailing : .leading
            
            VStack(alignment: alignment, spacing: 2) {
                if !fromMe {
                    UserNameView(user: burst.sender)
                        .font(
                            Font.custom("Inter", size: 10)
                                .weight(.medium)
                        )
                        .foregroundColor(Color.greyCool800)
                        .padding(.bottom, 4)
                }
                
                ForEach(burst.messages) { message in
                    VStack(alignment: alignment, spacing: 0) {
                        MessageBubble(message: message, alignment: alignment)
                            .id(message.eventId)
                        
                        if !message.reactions.isEmpty {
                            ChatMessageReactionsView(message: message, alignment: alignment)
                                .padding(.top, -4)
                                .padding(.bottom, 2)
                                .padding(.leading, 12)
                        }
                        
                        if !threaded && !message.replies.isEmpty {
                            NavigationLink(destination: ChatThreadView(room: burst.room, parent: message)) {
                                Label("Thread: \(message.replies.count) replies", systemImage: "bubble.left.and.bubble.right")
                                    .font(
                                        Font.custom("Inter", size: 14)
                                            .weight(.medium)
                                    )
                                    .foregroundColor(.greyCool1100)
                            }
                            .padding(.top, 2)
                            .padding(.leading, 6)
                            .padding(.bottom, 4)

                        }
                    }
                }
            }
            
            if !fromMe {
                Spacer()
                    .frame(width: 60)
                Spacer()
            }
        }
        .padding(.bottom, 8)
    }
}
