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
    @State var sheetType: MessageSheetType? = nil
    @State var showConfirmDelete = false
    
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
                    let backgroundColor = fromMe ? Color.lightPurple900 : Color.greyCool500
                    let foregroundColor = fromMe ? Color.lightGreyCool100 : Color.greyCool1100
                    
                    Text(content.body)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .font(
                            Font.custom("Inter", size: 14)
                                .weight(.medium)
                        )
                        .foregroundColor(foregroundColor)
                        .contextMenu {
                            MessageContextMenu(message: message, showReactions: true, sheetType: $sheetType, showMessageDeleteConfirmation: $showConfirmDelete)
                        }
                        .sheet(item: $sheetType) { st in
                            switch(st) {
                            case .emoji:
                                EmojiPicker(message: message)
                                
                            case .edit:
                                PostComposer(room: message.room, editing: message)
                                
                            case .reporting:
                                MessageReportingSheet(message: message)
                                
                            case .liked:
                                //LikedEmojiView(message: message, emojiUsersListModel: emojiUsersListModel)
                                Text("Coming soon") // FIXME
                            }
                        }
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


