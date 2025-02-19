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
    var container: ContainerRoom<Matrix.Room>
    @ObservedObject var room: Matrix.Room
    @ObservedObject var user: Matrix.User
    
    var body: some View {
        NavigationLink(destination: FollowingTimelineDetailsView(room: room, user: user, container: container)) {
            RoomAvatarView(room: room, avatarText: .none)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text("\(user.displayName ?? user.userId.username)")
                if DebugModel.shared.debugMode {
                    Text(room.roomId.stringValue)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                let followerCount = max(0, room.joinedMembers.count-1)
                let unit = followerCount > 1 ? "followers" : "follower"
                Text("\(room.name ?? "(???)") (\(followerCount) \(unit))")
            }
            .onAppear {
                user.refreshProfile()
            }
            
        }
    }
}
