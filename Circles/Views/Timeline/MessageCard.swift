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

import MarkdownUI
//import NativeMarkKit

enum MessageDisplayStyle {
    case timeline
    case photoGallery
    case composer
    case detail
}

struct MessageText: View {
    var text: String
    var paragraphs: [Substring]
    var markdown: MarkdownContent
    
    init(_ text: String) {
        self.text = text
        self.paragraphs = text.split(separator: "\n")
        self.markdown = MarkdownContent(text)
    }
    
    /*
    var body: some View {
        VStack(alignment: .leading) {
            if paragraphs.count > 1 {
                ScrollView {
                    VStack(alignment: .leading) {
                        //ForEach(0 ..< self.paragraphs.count ) { index in
                        //  let para = self.paragraphs[index]
                        ForEach(self.paragraphs, id: \.self) { para in
                            Text(para)
                                .multilineTextAlignment(.leading)
                                .font(.body)
                                .padding(.bottom, 5)
                        }
                    }
                }
            }
            else {
                Text(self.text)
                    .font(.body)
            }
        }
    }
    */
    
    var body: some View {
        /*
        if let fancyText = try? AttributedString(markdown: self.text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(fancyText)
        }
        else {
            return Text(self.text)
        }
        */
        Markdown(markdown)
            .textSelection(.enabled)
    }
}

struct MessageThumbnail: View {
    @ObservedObject var message: Matrix.Message
    
    var thumbnail: Image {
        Image(uiImage: message.thumbnail ?? UIImage())
    }
    
    var body: some View {
        ZStack {
            thumbnail
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundColor(.gray)
        }
    }
    
    
}

struct MessageTimestamp: View {
    var message: Matrix.Message
    
    var body: some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return Text(dateFormatter.string(from: message.timestamp))
            .font(.caption)
            .foregroundColor(Color.gray)
    }
}

struct MessageCard: MessageView {
    @ObservedObject var message: Matrix.Message
    var isLocalEcho = false
    var isThreaded = false
    @AppStorage("debugMode") var debugMode: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var galleries: ContainerRoom<GalleryRoom>
    //@State var showReplyComposer = false
    @State var reporting = false
    private let debug = false
    @State var showDetailView = false
    @State var sheetType: MessageSheetType? = nil
    
    init(message: Matrix.Message, isLocalEcho: Bool = false, isThreaded: Bool = false) {
        self.message = message
        self.isLocalEcho = isLocalEcho
        self.isThreaded = isThreaded
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
        return Text("\(message.timestamp, formatter: formatter)")
            .font(.footnote)
            .foregroundColor(.gray)
    }
    
    var relativeTimestamp: some View {
        // From https://noahgilmore.com/blog/swiftui-relativedatetimeformatter/
        let formatter = RelativeDateTimeFormatter()
        return Text("\(message.timestamp, formatter: formatter)")
            .font(.footnote)
            .foregroundColor(.gray)
    }
    
    var content: some View {
        VStack {
            if let content = message.content as? Matrix.MessageContent {
                switch(content.msgtype) {
                case .text:
                    if let textContent = content as? Matrix.mTextContent {
                        MessageText(textContent.body)
                        //Markdown(Document(textContent.body))
                        //NativeMarkText(textContent.body)
                        //.frame(minHeight: 30, maxHeight:400)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 5)
                    }
                    else {
                        EmptyView()
                    }
                    
                case .image:
                    if let imageContent = content as? Matrix.mImageContent {
                        HStack {
                            Spacer()
                            VStack(alignment: .center) {
                                MessageThumbnail(message: message)
                                //.padding(1)
                                
                                if let caption = imageContent.caption,
                                   let markdown = MarkdownContent(caption) {
                                    Markdown(markdown)
                                }
                            }
                            Spacer()
                        }
                    } else {
                        EmptyView()
                    }
                case .video:
                    if let videoContent = content as? Matrix.mVideoContent {
                        ZStack(alignment: .center) {
                            MessageThumbnail(message: message)
                            Image(systemName: "play.circle")
                        }
                        .frame(minWidth: 200, maxWidth: 400, minHeight: 200, maxHeight: 500, alignment: .center)
                    } else {
                        EmptyView()
                    }
                default:
                    if message.type == "m.room.encrypted" {
                        ZStack {
                            let bgColor = colorScheme == .dark ? Color.black : Color.white
                            Image(systemName: "lock.rectangle")
                                .resizable()
                                .foregroundColor(Color.gray)
                                .scaledToFit()
                                .padding()
                            VStack {
                                Text("ERROR")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Failed to decrypt message")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Message id: \(message.id)")
                                    .font(.footnote)
                            }
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .background(
                                bgColor
                                    .opacity(0.5)
                            )
                        }
                        /*
                         .onAppear {
                         print("Trying to decrypt...")
                         message.matrix.tryToDecrypt(message: message) { response in
                         if response.isSuccess {
                         message.objectWillChange.send()
                         }
                         }
                         }
                         */
                    }
                    else {
                        Text("This version of Circles can't display this message yet (\"\(message.type)\")")
                    }
                }
            } else {
                Text("Something went wrong")
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
    }

    var replyButton: some View {
        Button(action: {
            self.sheetType = .composer
        }) {
            //Label("Reply", systemImage: "bubble.right")
            Image(systemName: "bubble.right")
        }
    }

    var menuButton: some View {
        Menu {
        MessageContextMenu(message: message,
                           sheetType: $sheetType)
        }
        label: {
            //Label("More", systemImage: "ellipsis.circle")
            Image(systemName: "ellipsis.circle")
        }
    }

    var reactions: some View {
        HStack {
            //Spacer()
            let reactionCounts = self.message.reactions?.mapValues {
                $0.count
            }.sorted(by: >) ?? []
            
            ForEach(reactionCounts.prefix(5), id: \.key) { emoji, count in
                //Text(emoji)
                Text("\(emoji) \(count) ")
            }
            if reactionCounts.count > 5 {
                Text("...")
            }
        }
    }
    
    var footer: some View {
        VStack(alignment: .leading) {
            Divider()

            if let r = message.reactions,
               !r.isEmpty
            {
                reactions
            }
            
            //if displayStyle != .composer {
                HStack {
                    shield
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
            //}

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
            Text("Reactions: \(message.reactions?.keys.count ?? 0) Distinct reactions")
        }
    }
    
    var mainCard: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            
            MessageAuthorHeader(user: message.sender)

            if debugMode && self.debug {
                Text(message.eventId)
                    .font(.caption)
            }

            content
            
            if debugMode {
                details
                    .font(.caption)
            }
            
            HStack {
                Spacer()
                timestamp
            }

            footer
        }
        .frame(maxWidth: 800)
        .padding(.all, 3.0)
        .background(
            RoundedRectangle(cornerRadius: 4)
                //.foregroundColor(.init(light: .white, dark: .black))
                .foregroundColor(.background)
                .shadow(color: .gray, radius: 2, x: 0, y: 1)
        )

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

        linkWrapper
            .contextMenu {
                MessageContextMenu(message: message,
                                   sheetType: $sheetType)
            }
            .sheet(item: $sheetType) { st in
                switch(st) {

                case .composer:
                    MessageComposerSheet(room: message.room, parentMessage: message, galleries: galleries)

                case .detail:
                    MessageDetailSheet(message: message, displayStyle: .timeline)

                case .reactions:
                    EmojiPicker(message: message)

                case .reporting:
                    MessageReportingSheet(message: message)

                }
            }

    }
}
