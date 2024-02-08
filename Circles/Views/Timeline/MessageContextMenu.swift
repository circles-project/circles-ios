//
//  MessageContextMenu.swift
//  Circles
//
//  Created by Charles Wright on 7/6/21.
//

import SwiftUI
import UIKit
import Matrix


struct MessageContextMenu: View {
    var message: Matrix.Message
    @Binding var sheetType: MessageSheetType?

    var body: some View {

        let current = message.replacement ?? message
        if let content = current.content as? Matrix.MessageContent,
           content.msgtype == M_IMAGE,
           let imageContent = content as? Matrix.mImageContent
        {
            AsyncButton(action: {
                try await saveImage(content: imageContent)
            }) {
                Label("Save image", systemImage: "square.and.arrow.down")
            }

            if let thumbnail = current.thumbnail
            {
                let image = Image(uiImage: thumbnail)
                ShareLink(item: image, preview: SharePreview(imageContent.caption ?? "", image: image))
            }
        }

        Button(action: {
            message.objectWillChange.send()
        }) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }

        // Don't try to block yourself
        if message.sender.userId != message.room.session.creds.userId {
            Menu {
                AsyncButton(action: {
                    try await message.room.setPowerLevel(userId: message.sender.userId, power: -10)
                }) {
                    Label("Block sender from posting here", systemImage: "person.crop.circle.badge.xmark")
                }
                .disabled( !message.room.iCanChangeState(type: M_ROOM_POWER_LEVELS) )
                
                AsyncButton(action: {
                    try await message.room.kick(userId: message.sender.userId,
                                                reason: "Removed by \(message.room.session.whoAmI()) for message \(message.eventId)")
                }) {
                    Label("Remove sender", systemImage: "trash.circle")
                }
                .disabled( !message.room.iCanKick )
                
                AsyncButton(action: {
                    try await message.room.session.ignoreUser(userId: message.sender.userId)
                }) {
                    Label("Ignore sender", systemImage: "person.crop.circle.badge.minus")
                }
            } label: {
                Label("Block", systemImage: "xmark.shield")
            }
            
            Button(action: {
                //self.selectedMessage = self.message
                //self.showReportingView = true
                self.sheetType = .reporting
            }) {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                    Text("Report")
                }
            }
        }
        
        Button(action: {
            guard let content = message.content as? Matrix.MessageContent
            else {
                print("Failed to copy message \(message.eventId)")
                return
            }
            
            let pasteboard = UIPasteboard.general
            
            switch content.msgtype {
            case M_TEXT:
                guard let textContent = content as? Matrix.mTextContent
                else {
                    print("Failed to get content to copy m.text message \(message.eventId)")
                    return
                }
                pasteboard.string = textContent.body

            case M_IMAGE:
                guard let imageContent = content as? Matrix.mImageContent
                else {
                    print("Failed to get content to copy m.image message \(message.eventId)")
                    return
                }
                pasteboard.image = message.thumbnail
                
            default:
                print("Cannot copy msgtype \(content.msgtype)")
            }
        }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if message.sender.userId == message.room.session.creds.userId {
            Button(action: {
                self.sheetType = .edit
            }) {
                Label("Edit", systemImage: "pencil")
            }
        }
        
        if message.iCanRedact {
            Menu {
                AsyncButton(action: {
                    try await delete()
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.red)
                
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func delete() async throws {
        let content = message.content
        let session = message.room.session
        try await message.room.redact(eventId: message.eventId,
                                      reason: "Deleted by \(message.room.session.whoAmI())")
        // Now attempt to delete media associated with this event, if possible
        // Since the Matrix spec has no DELETE for media, this will probably fail, so don't worry if these calls throw errors
        if let messageContent = content as? Matrix.MessageContent {
            switch messageContent.msgtype {
            case M_IMAGE:
                if let imageContent = messageContent as? Matrix.mImageContent {
                    if let file = imageContent.file {
                        try? await session.deleteMedia(file.url)
                    }
                    if let url = imageContent.url {
                        try? await session.deleteMedia(url)
                    }
                    if let thumbnail_file = imageContent.thumbnail_file {
                        try? await session.deleteMedia(thumbnail_file.url)
                    }
                    if let thumbnail_url = imageContent.thumbnail_url {
                        try? await session.deleteMedia(thumbnail_url)
                    }
                }
            case M_VIDEO:
                if let videoContent = messageContent as? Matrix.mVideoContent {
                    if let file = videoContent.file {
                        try? await session.deleteMedia(file.url)
                    }
                    if let url = videoContent.url {
                        try? await session.deleteMedia(url)
                    }
                    if let thumbnail_file = videoContent.thumbnail_file {
                        try? await session.deleteMedia(thumbnail_file.url)
                    }
                    if let thumbnail_url = videoContent.thumbnail_url {
                        try? await session.deleteMedia(thumbnail_url)
                    }
                }
            default:
                print("Not deleting any media for msgtype \(messageContent.msgtype)")
            }
        }
    }

    func saveEncryptedImage(file: Matrix.mEncryptedFile) async throws {

        let session = message.room.session

        guard let data = try? await session.downloadAndDecryptData(file),
              let image = UIImage(data: data)
        else {
            print("Failed to get image for encrypted URL \(file.url)")
            return
        }
        
        print("Saving image...")
        let imageSaver = ImageSaver()
        await imageSaver.writeToPhotoAlbum(image: image)
        print("Successfully saved image from \(file.url)")
    }

    func savePlaintextImage(url: MXC) async throws {
        print("Trying to save image from URL \(url)")
        guard let data = try? await message.room.session.downloadData(mxc: url),
              let image = UIImage(data: data)
        else {
            print("Failed to get image for url \(url)")
            return
        }
        
        print("Saving image...")
        let imageSaver = ImageSaver()
        await imageSaver.writeToPhotoAlbum(image: image)
        print("Successfully saved image from \(url)")
    }

    func saveImage(content: Matrix.mImageContent) async throws {
        // Coming in, we have no idea what this m.image content may contain
        // It may have any mix of encrypted / unencrypted full-res image and thumbnail
        // So we try to be a little bit smart
        //   - We prefer the full-res image over the thumbnail
        //   - When trying to find an image (either full-res or thumbnail) we prefer the encrypted version over unencrypted
        // In other words, our preferences are:
        //   1. Full-res, encrypted
        //   2. Full-res, non encrypted
        //   3. Thumbnail, encrypted
        //   4. Thumbnail, non encrypted
        
        if let fullResFile = content.file {
            try await saveEncryptedImage(file: fullResFile)
        }
        else if let fullResUrl = content.url {
            try await savePlaintextImage(url: fullResUrl)
        }
        else if let thumbnailFile = content.thumbnail_file {
            try await saveEncryptedImage(file: thumbnailFile)
        }
        else if let thumbnailUrl = content.thumbnail_url {
            try await savePlaintextImage(url: thumbnailUrl)
        }
        else {
            print("Error: Can't save image -- No encrypted file or URL")
        }
    }

}

/*
struct MessageContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        MessageContextMenu()
    }
}
*/
