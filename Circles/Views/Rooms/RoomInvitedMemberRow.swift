//
//  CircleInvitedFollowerRow.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import Matrix

// This renders a row in a list, showing a user who we have invited to join one of our rooms
struct RoomInvitedMemberRow: View {
    var room: Matrix.Room
    @ObservedObject var user: Matrix.User
    
    @State var showConfirmCancel = false
    
    var body: some View {
        HStack {
            UserAvatarView(user: user)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading) {
                UserNameView(user: user)
                Text(user.userId.stringValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(role: .destructive, action: {
                // Cancel invite
                self.showConfirmCancel = true
            }) {
                Image(systemName: SystemImages.trash.rawValue)
            }
            .disabled(!room.iCanKick)
            .confirmationDialog(
                "Cancel invitation?",
                isPresented: $showConfirmCancel,
                actions: {
                    AsyncButton(role: .destructive, action: {
                        try await room.kick(userId: user.userId, reason: "Canceling invitation")
                    }) {
                        Text("Cancel invitation")
                    }
                }
            )
        }
    }
}
