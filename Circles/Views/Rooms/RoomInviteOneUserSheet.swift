//
//  RoomInviteOneUserSheet.swift
//  Circles
//
//  Created by Charles Wright on 12/15/23.
//

import SwiftUI
import Matrix

struct RoomInviteOneUserSheet: View {
    @ObservedObject var room: Matrix.Room
    @ObservedObject var user: Matrix.User
    
    @Environment(\.presentationMode) var presentation
    
    @State private var message = ""
    
    var subtitle: String {
        switch room.type {
        case ROOM_TYPE_CIRCLE:
            return "To follow my \(room.name ?? "") timeline"
        case ROOM_TYPE_GROUP:
            return "To join \(room.name ?? "a group")"
        case ROOM_TYPE_SPACE:
            return "To connect with \(room.name ?? "me")"
        case ROOM_TYPE_PHOTOS:
            return "To see photos in \(room.name ?? "a gallery")"
        default:
            return "To join \(room.name ?? "")"
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                Text("Inviting \(user.displayName ?? user.userId.stringValue)")
                    .font(.title2)
                Text(subtitle)
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Message:")
                TextEditor(text: $message)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray))
            }
            .padding()

            HStack {
                Spacer()
                
                Button(role: .destructive, action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .padding(5)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                AsyncButton(action: {
                    try await room.invite(userId: user.userId, reason: message.isEmpty ? nil : message)
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Send invitation")
                        .padding(5)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
    }
}

