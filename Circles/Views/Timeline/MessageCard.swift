//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MessageCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Foundation

enum MessageDisplayStyle {
    case timeline
    case photoGallery
}

struct MessageText: View {
    var text: String
    var paragraphs: [Substring]
    
    init(_ text: String) {
        self.text = text
        self.paragraphs = text.split(separator: "\n")
    }
    
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
}

struct MessageThumbnail: View {
    @ObservedObject var message: MatrixMessage
    
    var thumbnail: Image {
        guard let img = message.thumbnailImage ?? message.blurhashImage else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: img)
    }
    
    var body: some View {
        ZStack {
            thumbnail
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundColor(.gray)
            
            if message.thumbnailURL != nil && message.thumbnailImage == nil
            {
                ProgressView()
            }
        }
    }
    
    
}

struct MessageTimestamp: View {
    var message: MatrixMessage
    
    var body: some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return Text(dateFormatter.string(from: message.timestamp))
            .font(.caption)
            .foregroundColor(Color.gray)
    }
}

struct MessageCard: View {
    @ObservedObject var message: MatrixMessage
    var displayStyle: MessageDisplayStyle
    @Environment(\.colorScheme) var colorScheme
    @State var showReplyComposer = false
    @State var reporting = false
    private let debug = false
    @State var showDetailView = false

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
        return Text("Posted \(message.timestamp, formatter: formatter)")
            .font(.footnote)
            .foregroundColor(.gray)
    }
    
    var relativeTimestamp: some View {
        // From https://noahgilmore.com/blog/swiftui-relativedatetimeformatter/
        let formatter = RelativeDateTimeFormatter()
        return Text("Posted \(message.timestamp, formatter: formatter)")
            .font(.footnote)
            .foregroundColor(.gray)
    }
    
    var content: some View {
        VStack {
            switch(message.content) {
            case .text(let textContent):
                // FIXME Do some GeometryReader stuff here to scale the frame appropriately for the given screen size
                MessageText(textContent.body)
                    //.frame(minHeight: 30, maxHeight:400)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 5)
            case .image(let imageContent):
                HStack {
                    Spacer()
                    VStack(alignment: .center) {
                        MessageThumbnail(message: message)
                            .padding(3)

                        if let caption = getCaption(body: imageContent.body) {
                            Text(caption)
                                .padding(.horizontal, 3)
                                .padding(.bottom, 5)
                        }
                    }
                    Spacer()
                }
            case .video(let videoContent):
                ZStack(alignment: .center) {
                    MessageThumbnail(message: message)
                    Image(systemName: "play.circle")
                }
                .frame(minWidth: 200, maxWidth: 400, minHeight: 200, maxHeight: 500, alignment: .center)
            default:
                Text("This version of Circles can't display this message yet")
            }
        }
    }
    
    var avatarImage: Image {
        message.avatarImage != nil
            ? Image(uiImage: message.avatarImage!)
            : Image(systemName: "person.fill")
        // FIXME We can do better here.
        //       Use the SF Symbols for the user's initial(s)
        //       e.g. Image(sysetmName: "a.circle.fill")
    }
    
    var shield: some View {
         message.isEncrypted
            ? Image(systemName: "lock.shield")
                .foregroundColor(Color.blue)
            : Image(systemName: "xmark.shield")
                .foregroundColor(Color.red)
    }
    
    var footer: some View {
        HStack(alignment: .center) {
            
            shield
            
            if self.displayStyle == .photoGallery {
                //profileImage
                //ProfileImageView(user: message.matrix.getUser(userId: message.sender)!)
                avatarImage.resizable()
                .frame(width: 20, height: 20)
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Spacer()
            timestamp
            //relativeTimestamp
        }
        //.padding(.horizontal)
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type: \(message.type)")
            Text("Related: \(message.relatesToId ?? "none")")
            Text("BlurHash: \(message.blurhash ?? "none")")
            if let hash = message.blurhash {
                if let img = message.blurhashImage {
                    Text("BlurHash is \(Int(img.size.width))x\(Int(img.size.height))")
                }
            }
        }
    }
    
    var mainCard: some View {
        
        VStack(alignment: .leading, spacing: 2) {

            if displayStyle == .timeline {
                MessageAuthorHeader(user: message.matrix.getUser(userId: message.sender)!)
            }

            if KOMBUCHA_DEBUG && self.debug {
                Text(message.id)
                    .font(.caption)
            }

            content

            if KOMBUCHA_DEBUG {
                details
                    .font(.caption)
            }

            footer
        }
        .padding(.all, 3.0)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .shadow(color: .gray, radius: 2, x: 0, y: 1)
        )
        .contextMenu /*@START_MENU_TOKEN@*/{
            // Only allow replies for top-level posts
            // Otherwise it gets too crazy trying to display a threaded view on mobile
            if message.relatesToId == nil {
                Button(action: {self.showReplyComposer = true}) {
                    HStack {
                        Text("Reply")
                        Image(systemName: "bubble.right")
                    }
                }
            }
            if message.type == MatrixMsgType.image.rawValue {
                Button(action: saveImage) {
                    Label("Save image", systemImage: "square.and.arrow.down")
                }
                // FIXME Add if message.sender == me.id
                Button(action: {}) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            Button(action: {
                message.objectWillChange.send()
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Button(action: {
                self.showDetailView = true
            }) {
                Text("Show detailed view")
            }
            
            Menu {
                Button(action: {
                    message.room.setPowerLevel(userId: message.sender, power: 0) { response in
                        // Nothing we can do here, either way
                    }
                }) {
                    Label("Block sender from posting here", systemImage: "person.crop.circle.badge.xmark")
                }
                .disabled( !message.room.amIaModerator() )

                Button(action: {
                        message.room.kick(userId: message.sender,
                                          reason: "Removed by \(message.matrix.whoAmI()) for message \(message.id)")
                }) {
                    Label("Remove sender", systemImage: "trash.circle")
                }
                .disabled( !message.room.amIaModerator() )

                Button(action: {
                    message.room.ignoreUser(message.sender)
                }) {
                    Label("Ignore sender", systemImage: "person.crop.circle.badge.minus")
                }
            } label: {
                Label("Block", systemImage: "xmark.shield")
            }

            Button(action: {self.reporting = true}) {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                    Text("Report")
                }
            }
            Menu {
                Button(action: {
                    message.room.redact(message: message,
                                        reason: "Deleted by \(message.matrix.whoAmI())") { response in
                        // Nothing else to do?
                        // If it failed, it failed...
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.red)

            } label: {
                Label("Delete", systemImage: "trash")
            }
        }/*@END_MENU_TOKEN@*/
    }
    
    var reportingDialog: some View {
        VStack {
            MessageReportingSheet(message: message, show: self.$reporting)
        }
        .padding(.all, 3.0)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .shadow(color: .gray, radius: 2, x: 0, y: 1)
        )
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                mainCard
                
                if showReplyComposer {
                    RoomMessageComposer(room: message.room,
                                        isPresented: $showReplyComposer,
                                        inReplyTo: message)
                        .padding(.leading, 20)
                }
            }
            
            if reporting {
                reportingDialog
            }
        }

    }
    
    func saveEncryptedImage(content: mImageContent) {
        // FIXME TODO
    }
    
    func savePlaintextImage(content: mImageContent) {
        guard let fullresUrl: URL = content.url ?? content.info.thumbnail_url else {
            return
        }
        print("Trying to save image from URL \(fullresUrl)")
        // Are we really lucky and we already have it in cache?
        guard let cachedImage = message.matrix.getCachedImage(mxURI: fullresUrl.absoluteString) else {
            // If not, no worries, we just download it before we save it
            print("Need to download image from URL \(fullresUrl)")
            message.matrix.downloadImage(mxURI: fullresUrl.absoluteString) { image in
                print("Downloaded image from URL \(fullresUrl), saving...")
                let imageSaver = ImageSaver()
                imageSaver.writeToPhotoAlbum(image: image)
            }
            return
        }
        print("Image was in cache, saving...")
        let imageSaver = ImageSaver()
        imageSaver.writeToPhotoAlbum(image: cachedImage)
    }
    
    func saveImage() {
        switch(message.content) {
        case .image(let imageContent):
            if message.isEncrypted {
                saveEncryptedImage(content: imageContent)
                return
            }
            else {
                savePlaintextImage(content: imageContent)
            }
        default:
            return
        }
    }
}
