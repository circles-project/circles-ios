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
    
    @ViewBuilder
    var avatar: some View {
        UserAvatarView(user: burst.sender)
            .frame(width: 24, height: 24)
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            
            let fromMe = burst.sender.userId == burst.room.session.me.userId
            
            if fromMe {
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
                        MessageBubble(message: message)
                        
                        if !message.reactions.isEmpty {
                            ChatMessageReactionsView(message: message, alignment: alignment)
                                .padding(.top, -4)
                                .padding(.bottom, 2)
                                .padding(.leading, 12)
                        }
                    }
                }
            }
            
            if !fromMe {
                Spacer()
            }
        }
    }
}
