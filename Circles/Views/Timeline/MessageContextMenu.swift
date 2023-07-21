//
//  MessageContextMenu.swift
//  Circles
//
//  Created by Charles Wright on 7/6/21.
//

import SwiftUI
import Matrix


struct MessageContextMenu: View {
    var message: Matrix.Message
    @Binding var sheetType: MessageSheetType?

    var body: some View {
        /* // Moved the Reply button into the MessageCard itself
        // Only allow replies for top-level posts
        // Otherwise it gets too crazy trying to display a threaded view on mobile
        if message.relatesToId == nil {
            Button(action: {
                //self.selectedMessage = self.message
                //self.showReplyComposer = true
                self.sheetType = .composer
            }) {
                HStack {
                    Text("Reply")
                    Image(systemName: "bubble.right")
                }
            }
        }
        */

        if let content = message.content as? Matrix.MessageContent,
           content.msgtype == .image
        {
            Button(action: saveImage) {
                Label("Save image", systemImage: "square.and.arrow.down")
            }

            if message.sender.userId == message.room.session.creds.userId {
                Button(action: {}) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }

        Button(action: {
            message.objectWillChange.send()
        }) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }

        Button(action: {
            self.sheetType = .detail
        }) {
            Label("Show detailed view", systemImage: "magnifyingglass")
        }

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
        Menu {
            AsyncButton(action: {
                try await message.room.redact(eventId: message.eventId,
                                              reason: "Deleted by \(message.room.session.whoAmI())")
            }) {
                Label("Delete", systemImage: "trash")
            }
            .disabled(!message.room.iCanRedact)
            .foregroundColor(.red)

        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    func saveEncryptedImage(content: Matrix.mImageContent) {
        /*
        guard let file = content.file ?? content.info.thumbnail_file else {
            print("SAVEIMAGE\tError: Encrypted image doesn't have an encrypted file :(")
            return
        }
        let url = file.url
        let matrix = message.room.session

        guard let cachedImage = matrix.getCachedEncryptedImage(mxURI: url.absoluteString) else {
            matrix.downloadEncryptedImage(fileinfo: file, mimetype: content.info.mimetype) { response in
                switch response {
                case .failure(let err):
                    print("SAVEIMAGE\tError: Failed to download encrypted image - \(err)")
                case .success(let img):
                    print("SAVEIMAGE\tSuccess!  Downloaded encrypted file.  Saving...")
                    let imageSaver = ImageSaver()
                    imageSaver.writeToPhotoAlbum(image: img)
                }
            }
            return
        }
        print("SAVEIMAGE\tEncrypted image was already in cache.  Saving...")
        let imageSaver = ImageSaver()
        imageSaver.writeToPhotoAlbum(image: cachedImage)
        */
    }

    func savePlaintextImage(content: Matrix.mImageContent) {
        /*
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
        */
    }

    func saveImage() {
        /*
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
            print("SAVEIMAGE\tTried to saveImage on something that wasn't an m.image (eventId = \(message.id))")
            return
        }
        */
    }

}

/*
struct MessageContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        MessageContextMenu()
    }
}
*/
