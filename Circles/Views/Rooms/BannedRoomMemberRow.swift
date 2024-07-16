//
//  BannedRoomMemberRow.swift
//  Circles
//
//  Created by Charles Wright on 4/15/24.
//

import SwiftUI
import Matrix

struct BannedRoomMemberRow: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var room: Matrix.Room
    
    @State var showConfirmUnban = false
    
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
            Button(action: {
                self.showConfirmUnban = true
            }) {
                Label("Un-ban", systemImage: "trash.slash")
            }
            .disabled(!room.iCanUnban(userId: user.userId))
            .confirmationDialog(
                "Confirm un-banning",
                isPresented: $showConfirmUnban,
                actions: {
                    AsyncButton(action: {}) {
                        Text("Un-ban \(user.displayName ?? user.userId.stringValue)")
                    }
                },
                message: {
                    Label("This will allow the user to re-join in the future", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            )
        }
    }
}


