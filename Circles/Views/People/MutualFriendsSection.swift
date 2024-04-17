//
//  MutualFriendsSection.swift
//  Circles
//
//  Created by Charles Wright on 4/17/24.
//

import SwiftUI
import Matrix

struct MutualFriendsSection: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var profile: ProfileSpace
    
    @State var mutualFriends: [Matrix.User]? = nil

    
    var body: some View {
        LazyVStack(alignment: .leading) {
            Text("MUTUAL FRIENDS")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top)
            if let friends = mutualFriends {
                if friends.isEmpty {
                    Text("No mutual friends")
                        .padding()
                } else {
                    ForEach(friends) { friend in
                        PersonHeaderRow(user: friend, profile: profile)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                let session = user.session
                // First find the set of circles that we're both in
                let rooms: [Matrix.Room] = session.rooms.values.filter { room in
                    room.type == ROOM_TYPE_CIRCLE && room.joinedMembers.contains(user.userId)
                }
                // Find the users in those circles who are not (1) me or (2) them
                let users: Set<Matrix.User> = rooms.reduce([], { curr, room in
                    let roomMembers: [Matrix.User] = room.joinedMembers.filter {
                        $0 != user.userId && $0 != user.session.creds.userId
                    }.compactMap {
                        session.getUser(userId: $0)
                    }
                    return curr.union(roomMembers)
                })
                // Sort the set in order to get an Array
                let sortedUsers = users.sorted(by: {u0,u1 in
                    u0.userId.stringValue < u1.userId.stringValue
                })
                // Update the UI state on the main thread
                await MainActor.run {
                    self.mutualFriends = sortedUsers
                }
            }
        }
    }
}
