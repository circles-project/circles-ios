//
//  CircleFollowingRow.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import Matrix

// This shows a row in a list representing a friend's timeline that we are following in one of our circles
// This needs to be its own type so that it can keep local state `showConfirmUnfollow`
// We wouldn't need this if the SwiftUI `.confirmationDialog` actually used its `presenting:` argument properly -- then we could just put the confirmation dialog in the parent view -- but oh well
struct CircleFollowingRow: View {
    var space: CircleSpace
    @ObservedObject var room: Matrix.Room
    @ObservedObject var user: Matrix.User
    
    @State var showConfirmUnfollow = false
    
    var body: some View {
        HStack {
            RoomAvatar(room: room, avatarText: .none)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 40, height: 40)
                .onAppear {
                    room.updateAvatarImage()
                }
            
            Text("\(user.displayName ?? user.userId.username) - \(room.name ?? "(???)")")
                .onAppear {
                    user.refreshProfile()
                }
            
            Spacer()
            Button(role: .destructive, action: {
                self.showConfirmUnfollow = true
            }) {
                Label("Unfollow", systemImage: "trash")
            }
            .confirmationDialog(
                Text("Confirm un-follow"),
                isPresented: $showConfirmUnfollow) {
                    AsyncButton(action: {
                        print("Un-following roomId = \(room.roomId)")
                        try await space.removeChildRoom(room.roomId)
                    }) {
                        Text("Un-follow")
                    }
                }
        }
    }
}
