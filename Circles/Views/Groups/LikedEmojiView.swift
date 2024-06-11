//
//  LikedEmojiView.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 5/29/24.
//

import Matrix
import SwiftUI

struct EmojiUsersListModel: Codable, Equatable {
    let userId: UserId
    let emoji: String
    let id: String
}

private enum UIConstants {
    static let imageSize: CGFloat = 50
    static let cornerRadius: CGFloat = 25
    static let buttonHeight: CGFloat = 60
    static let presentationHeight: CGFloat = 300
}

struct LikedEmojiView: View {
    @ObservedObject var message: Matrix.Message
    @State var emojiUsersListModel: [EmojiUsersListModel]
    
    private var allReactions: [Dictionary<String, Int>.Element] {
        self.message.reactions
            .mapValues { userIds in
                userIds.filter {
                    !self.message.room.session.ignoredUserIds.contains($0)
                }
                .count
            }
            .filter { $0.value > 0 }
            .sorted(by: >)
    }
    
    private var filledEmojiUsersList: some View {
        ForEach(allReactions, id: \.key) { emoji, count in
            let users = message.reactions[emoji] ?? []
            
            HStack { }
                .onAppear {
                    users.forEach {
                        emojiUsersListModel.append(.init(userId: $0, emoji: emoji, id: NSUUID().uuidString))
                    }
                }
        }
    }
    
    private var emojiView: some View {
        let height = CGFloat(emojiUsersListModel.count + 1) * UIConstants.buttonHeight // height of all elements
        let preferableHeight = height > UIConstants.presentationHeight ? UIConstants.presentationHeight : height // height for sheetView
        return EmojiListView(room: message.room, users: emojiUsersListModel)
            .presentationDetents([.height(preferableHeight), .medium])
    }
    
    private var clearEmojiUsersList: some View {
        Button("") { }
            .onAppear {
                emojiUsersListModel = []
            }
    }
    
    var body: some View {
        filledEmojiUsersList
        emojiView
        clearEmojiUsersList
    }
}

private struct EmojiListView: View {
    @ObservedObject var room: GroupRoom
    var users: [EmojiUsersListModel]
    
    private var button: some View {
        ForEach(users, id: \.id) { userModel in
            let user = room.session.getUser(userId: userModel.userId)

            AsyncButton(action: { }, label: {
                if let img = user.avatar {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIConstants.imageSize, height: UIConstants.imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                    
                } else {
                    Circle()
                        .frame(width: UIConstants.imageSize, height: UIConstants.imageSize)
                        .overlay(
                            Text(user.displayName?.first?.uppercased() ?? "Unknown user")
                                .clipShape(ContainerRelativeShape()).padding()
                                .foregroundColor(Color.white)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                }
                Text(user.displayName ?? userModel.userId.username)
                    .foregroundStyle(Color.gray)
                Spacer()
                Text(userModel.emoji)
                    .font(.largeTitle)
            })
            .disabled(true)
            .frame(height: UIConstants.buttonHeight)
            
            if users.last != userModel {
                Divider()
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                button
            }
            .padding()
        }
    }
}
