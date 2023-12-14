//
//  FollowingTimelineDetailsView.swift
//  Circles
//
//  Created by Charles Wright on 12/14/23.
//

import SwiftUI
import Matrix

struct FollowingTimelineDetailsView: View {
    @ObservedObject var room: Matrix.Room
    @ObservedObject var user: Matrix.User
    @ObservedObject var circle: CircleSpace
    
    @State var showConfirmUnfollow = false

    
    var body: some View {
        let session = room.session
        let name = room.name ?? "\(user.displayName ?? user.userId.username)'s timeline"
        let title = "Details for Timeline \"\(name)\""
        VStack {
            Form {
                Section("General") {
                    Label("Name", systemImage: "circles.hexagonpath.fill")
                        .badge(room.name ?? "(unknown)")

                }
                
                Section("Creator") {
                    NavigationLink(destination: GenericPersonDetailView(user: user)) {
                        MessageAuthorHeader(user: user)
                    }
                }
                
                Section("Followers") {
                    let followerIds = room.joinedMembers.filter { $0 != user.userId }
                    ForEach(followerIds) { followerId in
                        let follower = session.getUser(userId: followerId)
                        //Text(follower.displayName ?? follower.userId.stringValue)
                        MessageAuthorHeader(user: follower)
                    }
                }
                
                Section("Unfollow") {
                    Button(role: .destructive, action: {
                            showConfirmUnfollow = true
                    }) {
                        Label("Unfollow this timeline", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .confirmationDialog(
                        Text("Confirm un-follow"),
                        isPresented: $showConfirmUnfollow) {
                            AsyncButton(role: .destructive, action: {
                                print("Un-following roomId = \(room.roomId)")
                                try await circle.removeChildRoom(room.roomId)
                            }) {
                                Text("Unfollow")
                            }
                        }
                }
                
            }
        }
        .navigationTitle(title)
    }
}

