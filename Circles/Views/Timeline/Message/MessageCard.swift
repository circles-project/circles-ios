//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MessageCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Foundation
import Matrix
import AVKit

import MarkdownUI
//import NativeMarkKit

enum MessageDisplayStyle {
    case timeline
    case photoGallery
    case composer
}

class MessageCardViewModel: ObservableObject {
    @Published var showCommentsSheet = false // stupid hack that I used to fix a bug with the sheet that sometimes doesn't appear for posts located further down (after scrolling)
}

struct MessageCard: MessageView {
    @ObservedObject var message: Matrix.Message
    var isLocalEcho = false
    var isThreaded = false
    @State var emojiUsersListModel: [EmojiUsersListModel] = []
    @Environment(\.colorScheme) var colorScheme
    //@State var showReplyComposer = false
    @State var reporting = false
    private let debug = false
    @State var sheetType: MessageSheetType? = nil
    @State var showAllReactions = false
    @StateObject private var viewModel = MessageCardViewModel()
    var iCanReact: Bool
    @State var showMessageDeleteConfirmation = false
    
    let footerFont: Font = Font.custom("Inter", size: 14)
                               .weight(.medium)
    let footerForegroundColor = Color.greyCool1000
    
    init(message: Matrix.Message, isLocalEcho: Bool = false, isThreaded: Bool = false) {
        self.message = message
        self.isLocalEcho = isLocalEcho
        self.isThreaded = isThreaded
        self.iCanReact = message.room.iCanSendEvent(type: M_REACTION)
    }

    func getCaption(body: String) -> String? {
        // By default, Matrix sets the text body to be the filename
        // But we want to use it for an image caption
        // So we want to ignore the obvious filenames, and let through anything that was actually written by a human
        // This is the cheap, quick, and dirty version.
        // Whoever heard of a regex anyway???
        if body.starts(with: "ima_") && body.hasSuffix(".jpeg") && body.split(separator: " ").count == 1 {
            return nil
        }
        return body
    }
    
    var timestamp: some View {
        // If the message has been edited/replaced, then we should show the new timestamp
        // Otherwise we should show the original timestamp
        let current = message.replacement ?? message
        
        let formattedTimestampString = RelativeTimestampFormatter.format(date: current.timestamp)
        
        let icon = message.replacement == nil ? SystemImages.clock : SystemImages.pencil
        
        return HStack(alignment: .center, spacing: 2) {
            Text("\(Image(systemName: icon.rawValue))")
            Text(formattedTimestampString)
        }
    }
    

    
    @ViewBuilder
    var commentsButton: some View {
        Button(action: {
            // show the thread view
            self.viewModel.showCommentsSheet = true
        }) {
            HStack(alignment: .center, spacing: 5) {
                Image(systemName: "bubble.left")
                    .frame(width: 20, height: 20)
                let count = message.replies.count
                let units = count == 1 ? "comment" : "comments"
                Text("\(count) \(units)")
            }
            .font(footerFont)
            .foregroundColor(footerForegroundColor)
        }
    }

    
    @ViewBuilder
    var header: some View {
        HStack(alignment: .center, spacing: 8) {
            UserAvatarView(user: message.sender)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                UserNameView(user: message.sender)
                    .font(
                        Font.custom("Nunito", size: 14)
                            .weight(.heavy)
                    )
                    .foregroundColor(.greyCool1100)
                timestamp
                    .font(
                        Font.custom("Nunito", size: 12)
                            .weight(.semibold)
                    )
                    .foregroundColor(.greyCool800)
            }
            .padding(.leading, 0)
            .padding(.trailing, 8)

            .padding(.vertical, 0)
            
            Spacer()
            menuButton
        }
        .padding(.horizontal, 0)
        .padding(.top, 0)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    var menuButton: some View {
        Menu {
            MessageContextMenu(message: message,
                               sheetType: $sheetType,
                               showMessageDeleteConfirmation: $showMessageDeleteConfirmation)
        }
        label: {
            //Label("More", systemImage: SystemImages.ellipsisCircle.rawValue)
            Image(systemName: "ellipsis")
                .frame(width: 18, height: 18)
                .foregroundColor(.greyCool1000)
        }
        .confirmationDialog("Delete Message", isPresented: $showMessageDeleteConfirmation, actions: {
            AsyncButton(role: .destructive, action: {
                self.showMessageDeleteConfirmation = false
                try await deleteAndPurge(message: message)
            }) {
                Text("Confirm deleting the message")
            }
        })
    }
    
    var footer: some View {

        HStack(alignment: .top) {
            HStack(alignment: .top, spacing: 24) {
                LikeButton(message: message)
                
                if !isThreaded {
                    commentsButton
                }
            }
            .padding(0)
            .frame(width: 176, alignment: .topLeading)
            
            Spacer()
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .top)

    }

    var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EventId: \(message.eventId)")
            Text("Type: \(message.type)")
            Text("Related to: \(message.relatedEventId ?? "none")")
            Text("Reply to: \(message.replyToEventId ?? "none")")
            if let content = message.content as? RelatedEventContent {
                Text("relType: \(content.relationType ?? "n/a")")
                Text("related event_id: \(content.relatedEventId ?? "n/a")")
                Text("m.in_reply_to: \(content.replyToEventId ?? "n/a")")
            }
            Text("Reactions: \(message.reactions.keys.count) Distinct reactions")
            if let content = message.content as? Matrix.MessageContent {
                Text(content.debugString)
            }
        }
    }

    @ViewBuilder
    var mainCard: some View {
        
        VStack(alignment: .leading, spacing: 2) {

            header

            if DebugModel.shared.debugMode && self.debug {
                Text(message.eventId)
                    .font(.caption)
            }

            MessageContentView(message: message)
                .padding(.bottom, 10)
            
            if DebugModel.shared.debugMode {
                details
                    .font(.caption)
            }

            footer
        }
        .padding(16)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(12)
        .onAppear {
            if message.sender.userId != message.room.session.creds.userId {
                print("Updating m.read for room \(message.roomId) to be \(message.eventId)")
                Task {
                    try await message.room.sendReadReceipt(eventId: message.eventId, threadId: message.threadId)
                }
            }
        }
    }
    
    var linkWrapper: some View {
        HStack {
            if isThreaded {
                mainCard
            } else {
                NavigationLink(destination: ThreadView<MessageCard>(room: message.room, root: message)) {
                    mainCard
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    var body: some View {
        //linkWrapper

        mainCard
            .contextMenu {
                MessageContextMenu(message: message,
                                   sheetType: $sheetType,
                                   showMessageDeleteConfirmation: $showMessageDeleteConfirmation)
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
                    LikedEmojiView(message: message, emojiUsersListModel: emojiUsersListModel)
                }
            }
            .sheet(isPresented: $viewModel.showCommentsSheet) {
                CommentsView(room: message.room, parent: message)
                    .presentationDetents([.medium, .large])
            }
    }
}
