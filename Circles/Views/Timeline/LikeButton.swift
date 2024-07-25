//
//  LikeButton.swift
//  Circles
//
//  Created by Charles Wright on 7/19/24.
//

import SwiftUI
import Matrix

struct LikeButton: View {
    @ObservedObject var message: Matrix.Message
    
    var body: some View {
        let likers = message.reactions["❤️"] ?? []
        let iLikedThisMessage = likers.contains(message.room.session.creds.userId)
        let iCanReact = message.room.iCanSendEvent(type: M_REACTION)

        AsyncButton(action: {
            // send ❤️ emoji reaction if we have not sent it yet
            // Otherwise retract it
            if iLikedThisMessage {
                // Redact the previous reaction message
                try await message.sendRemoveReaction("❤️")
            } else {
                // Send the reaction
                try await message.sendReaction("❤️")
            }
        }) {
            HStack(alignment: .center, spacing: 2) {
                let icon = iLikedThisMessage ? SystemImages.heartFill : SystemImages.heart
                let color = iLikedThisMessage ? Color.accentColor : Color.primary
                Image(systemName: icon.rawValue)
                    .frame(width: 20, height: 20)
                    .foregroundColor(color)
                Text("\(message.reactions["❤️"]?.count ?? 0)")
            }
            .font(Font.custom("Inter", size: 14).weight(.medium))
            .foregroundColor(Color.greyCool1000)
        }
        .disabled(!iCanReact)
    }
}

