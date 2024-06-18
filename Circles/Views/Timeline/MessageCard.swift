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

struct TextContentView: View {
    var text: String
    var markdown: MarkdownContent
    
    init(_ text: String) {
        self.text = text
        self.markdown = MarkdownContent(text)
    }
    
    var body: some View {
        Markdown(markdown)
            .textSelection(.enabled)
    }
}

struct ImageContentView: View {
    @ObservedObject var message: Matrix.Message
    @State var markdownHeight: CGFloat = 1000
    
    var body: some View {
        HStack {
            if let imageContent = message.content as? Matrix.mImageContent {
                //Spacer()
                VStack(alignment: .center) {
                    MessageThumbnail(message: message, aspectRatio: .fill)
                        .frame(maxHeight: 500)
                    HStack {
                        if let caption = imageContent.caption {
                            let markdown = MarkdownContent(caption)
                            Markdown(markdown)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear
                                            .onAppear {
                                                markdownHeight = proxy.size.height
                                            }
                                    }
                                )
                        }
                        Spacer()
                    }
                    .frame(maxHeight: markdownHeight, alignment: .leading)
                    .background(Color.background)
                }
                //Spacer()
            } else {
                EmptyView()
            }
        }
    }
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
    var iCanReact: Bool
    @State var showMessageDeleteConfirmation = false
    
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // If the message has been edited/replaced, then we should show the new timestamp
        // Otherwise we should show the original timestamp
        let current = message.replacement ?? message
        
        let edited: String = current.relationType == M_REPLACE ? "Edited " : ""
        let formattedTimestampString: String = formatter.string(from: current.timestamp)
        
        let text = edited + formattedTimestampString
        
        return Text(text)
            .font(.footnote)
            .foregroundColor(.gray)
    }
    
    var content: some View {
        VStack {
            // If the message has been edited/replaced, then we should show the new content
            // Otherwise we should show the original content
            let current = message.replacement ?? message
            
            if let content = current.content as? Matrix.MessageContent {
                switch(content.msgtype) {
                case M_TEXT:
                    if let textContent = content as? Matrix.mTextContent {
                        TextContentView(textContent.body)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }
                    
                case M_IMAGE:
                    ImageContentView(message: current)
                        .clipShape(Rectangle())
                    
                case M_VIDEO:
                    VideoContentView(message: current)
                
                // Poll event handling is temporary until proper support is implemented
                case ORG_MATRIX_MSC3381_POLL_START:
                    if let pollContent = content as? PollStartContent {
                        let pollText = "Poll: \(pollContent.message)\n\n"
                        let answersText = pollContent.start.answers.enumerated().map { "\t\($0): \($1.answer.body)\n" }.joined()
                                                
                        TextContentView(pollText + answersText)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }

                case ORG_MATRIX_MSC3381_POLL_RESPONSE:
                    if let pollContent = current.event.content as? PollResponseContent,
                       let pollId = pollContent.relatesTo.eventId,
                       let poll = current.room.timeline[pollId]?.event.content as? PollStartContent,
                       let vote = poll.start.answers.filter({ $0.id == pollContent.selections.first }).first {

                        if poll.start.kind == PollStartContent.PollStart.Kind.open {
                            TextContentView("Voted for \(vote.answer.body)")
                                .padding(.horizontal, 3)
                                .padding(.vertical, 5)
                        }
                        else {
                            TextContentView("Voted")
                                .padding(.horizontal, 3)
                                .padding(.vertical, 5)
                        }
                    }
                    else {
                        EmptyView()
                    }
                
                case ORG_MATRIX_MSC3381_POLL_END:
                    if let pollContent = current.event.content as? PollEndContent {
                        TextContentView(pollContent.text)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }
                    
                default:
                    Text("This version of Circles can't display this message yet (\"\(message.type)\")")
                        .foregroundColor(.red)
                
                } // end switch
                
            } else if current.type == M_ROOM_ENCRYPTED {
                VStack {
                    let bgColor = colorScheme == .dark ? Color.black : Color.white
                    BasicImage(systemName: "lock.rectangle")
                        .foregroundColor(Color.gray)
                        .frame(width: 240, height: 240)
                        .padding()
                    VStack {
                        Label("Could not decrypt message", systemImage: "exclamationmark.triangle")
                            .font(.title2)
                            .fontWeight(.semibold)
                        if DebugModel.shared.debugMode {
                            Text("Message id: \(message.id)")
                                .font(.footnote)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .background(
                        bgColor
                            .opacity(0.5)
                    )
                    .padding(.bottom, 2)
                }
                 .onAppear {
                     print("Trying to decrypt message \(current.eventId) ...")
                     Task {
                         try await current.decrypt()
                     }
                 }
            } else {
                Text("Something went wrong.  Circles failed to parse a message of type \"\(current.type)\".")
                    .foregroundColor(.red)
            }
        }
    }
    
    var avatarImage: Image {
        message.sender.avatar != nil
            ? Image(uiImage: message.sender.avatar!)
            : Image(systemName: "person.fill")
        // FIXME We can do better here.
        //       Use the SF Symbols for the user's initial(s)
        //       e.g. Image(sysetmName: "a.circle.fill")
    }
    
    @ViewBuilder
    var shield: some View {
        if isLocalEcho {
            ProgressView()
        } else if message.isEncrypted {
            Image(systemName: "lock.fill")
                .foregroundColor(Color.blue)
        } else {
            Image(systemName: "lock.slash.fill")
                .foregroundColor(Color.red)
        }
    }

    var likeButton: some View {
        Button(action: {
            self.sheetType = .reactions
        }) {
            //Label("Like", systemImage: "heart")
            Image(systemName: "heart")
        }
        .disabled(!iCanReact)
    }

    var replyButton: some View {
        NavigationLink(destination: PostComposerScreen(room: message.room, parentMessage: message)) {
            //Label("Reply", systemImage: "bubble.right")
            Image(systemName: "bubble.right")
        }
    }

    var menuButton: some View {
        Menu {
            MessageContextMenu(message: message,
                               sheetType: $sheetType,
                               showMessageDeleteConfirmation: $showMessageDeleteConfirmation)
        }
        label: {
            //Label("More", systemImage: "ellipsis.circle")
            Image(systemName: "ellipsis.circle")
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

    var reactions: some View {
        VStack {
            //Spacer()
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
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    
                    ForEach(reactionCounts, id: \.key) { emoji, count in
                        let userId = message.room.session.creds.userId
                        let users = message.reactions[emoji] ?? []
                        
                        if users.contains(userId) {
                            AsyncButton(action: {
                                // We already sent this reaction...  So redact it
                                try await message.sendRemoveReaction(emoji)
                            }) {
                                Text("\(emoji) \(count)")
                            }
                            .buttonStyle(ReactionsButtonStyle(buttonColor: .blue))
                        } else {
                            AsyncButton(action: {
                                // We have not sent this reaction yet..  Send it
                                try await message.sendReaction(emoji)
                            }) {
                                Text("\(emoji) \(count)")
                            }
                            .disabled(!iCanReact)
                            .buttonStyle(ReactionsButtonStyle(buttonColor: Color(UIColor.systemGray5)))
                        }
                    }
                    
                    if allReactionCounts.count > limit {
                        if !showAllReactions {
                            Button(action: {self.showAllReactions = true}) {
                                Text("(more)")
                                    .font(.subheadline)
                            }
                        } else {
                            Button(action: {self.showAllReactions = false}) {
                                Text("(less)")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .foregroundColor(.secondary)
        //.padding(2)
    }
    
    var footer: some View {
        VStack(alignment: .leading) {
            
            //Divider()

            HStack {
                shield
                //Spacer()
                timestamp
                Spacer()
                likeButton
                if message.relatedEventId == nil {
                    replyButton
                }
                menuButton
            }
            .padding(.top, 3)
            .padding(.horizontal, 3)
            .font(.headline)
            
            let reactionsFooterAction = message.reactions.values.map {
                !$0.isEmpty ? "show" : "hide"
            }
            if reactionsFooterAction.rawValue.contains("show")
            {
                Divider()

                reactions
            } else {
                reactions.hidden()
            }

        }
        .padding(.bottom, 3)
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
    
    var mainCard: some View {
        
        let shadowColor: Color = message.mentionsMe ? .accentColor : .gray
        let shadowRaduis: CGFloat = message.mentionsMe ? 3 : 2
        
        return VStack(alignment: .leading, spacing: 2) {
            
            MessageAuthorHeader(user: message.sender)

            if DebugModel.shared.debugMode && self.debug {
                Text(message.eventId)
                    .font(.caption)
            }

            content
            
            if DebugModel.shared.debugMode {
                details
                    .font(.caption)
            }

            footer
        }
        .padding(.all, 3.0)
        .background(
            RoundedRectangle(cornerRadius: 4)
                //.foregroundColor(.init(light: .white, dark: .black))
                .foregroundColor(.background)
                .shadow(color: shadowColor, radius: shadowRaduis, x: 0, y: 0)
        )
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
        ZStack {
            mainCard
                .contextMenu {
                    MessageContextMenu(message: message,
                                       sheetType: $sheetType,
                                       showMessageDeleteConfirmation: $showMessageDeleteConfirmation)
                }
                .sheet(item: $sheetType) { st in
                    switch(st) {
                    case .reactions:
                        EmojiPicker(message: message)
                        
                    case .reporting:
                        MessageReportingSheet(message: message)
                        
                    case .liked:
                        LikedEmojiView(message: message, emojiUsersListModel: emojiUsersListModel)
                    }
                }
        }
    }
}
