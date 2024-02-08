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
                try await saveImage(content: imageContent, session: message.room.session)
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
                    try await deleteAndPurge(message: message)
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.red)
                
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
