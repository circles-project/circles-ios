//
//  ChatMessageReactionsView.swift
//  Circles
//
//  Created by Charles Wright on 8/15/24.
//

import SwiftUI
import Matrix

struct ChatMessageReactionsView: View {
    @ObservedObject var message: Matrix.Message
    var alignment: HorizontalAlignment
    @State var showAllReactions = false
    
    var body: some View {
        HStack(spacing: 4) {
            
            let allReactionCounts = self.message.reactions
                .mapValues { userIds in
                    userIds.filter {
                        !self.message.room.session.ignoredUserIds.contains($0)
                    }
                    .count
                }
                .filter { (key,value) in
                    value > 0
                }
                .sorted(by: >)
            
            let limit = 3
            let reactionCounts = showAllReactions ? allReactionCounts : Array(allReactionCounts.prefix(limit))
            let iCanReact = message.room.iCanSendEvent(type: M_REACTION)
            

            ForEach(reactionCounts, id: \.key) { emoji, count in
                let userId = message.room.session.creds.userId
                let users = message.reactions[emoji] ?? []
                let text = count > 1 ? "\(emoji) \(count)" : emoji

                if users.contains(userId) {
                    AsyncButton(action: {
                        // We already sent this reaction...  So redact it
                        try await message.sendRemoveReaction(emoji)
                    }) {
                        Text(text)
                    }
                    .buttonStyle(ReactionsButtonStyle(buttonColor: .purple700))
                } else {
                    AsyncButton(action: {
                        // We have not sent this reaction yet..  Send it
                        try await message.sendReaction(emoji)
                    }) {
                        Text(text)
                    }
                    .disabled(!iCanReact)
                    .buttonStyle(ReactionsButtonStyle(buttonColor: .greyCool900))
                }
            }
            
            let notShownCount = allReactionCounts.count - limit
            if notShownCount > 0 {
                if !showAllReactions {
                    Button(action: {self.showAllReactions = true}) {
                        Text("(\(notShownCount) more)")
                    }
                } else {
                    Button(action: {self.showAllReactions = false}) {
                        Text("(less)")
                    }
                }
            }
        }
        .font(
            Font.custom("Inter", size: 12)
                .weight(.medium)
        )
        .foregroundColor(.secondary)
    }
}

