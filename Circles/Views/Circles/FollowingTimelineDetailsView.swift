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
    @ObservedObject var container: ContainerRoom<Matrix.Room>
    
    @State var showConfirmUnfollow = false

    
    var body: some View {
        let session = room.session
        let name = room.name ?? "\(user.displayName ?? user.userId.username)'s timeline"
        let title = "Details for Timeline \"\(name)\""
        VStack {
            Form {
                Section("General") {
                    Text("Timeline")
                        .badge(room.name ?? "(unknown)")
                    
                    NavigationLink(destination: RoomMemberDetailView(user: user, room: room)) {
                        Text("Creator")
                            .badge(user.displayName ?? user.userId.stringValue)
                    }
                    
                    HStack {
                        Text("Cover image")
                        Spacer()
                        RoomAvatarView(room: room, avatarText: .none)
                            .frame(width: 80, height: 80)                        
                    }
                    
                    if room.joinRule == .knock,
                       let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/timeline/\(room.roomId.stringValue)"),
                       let qr = qrCode(url: url)
                    {
                        HStack {
                            Text("QR code")
                            Spacer()
                            BasicImage(uiImage: qr)
                                .frame(width: 80, height: 80)
                        }
                    }
                    
                }
                
                Section("Timeline") {
                    NavigationLink(destination: SingleTimelineView(room: room)) {
                        Text("See posts from this timeline")
                    }
                }
                

                
                Section("Followers") {
                    let followerIds = room.joinedMembers.filter { $0 != user.userId }
                    ForEach(followerIds) { followerId in
                        let follower = session.getUser(userId: followerId)
                        //Text(follower.displayName ?? follower.userId.stringValue)
                        
                        NavigationLink(destination: RoomMemberDetailView(user: follower, room: room)) {
                            MessageAuthorHeader(user: follower)
                        }
                    }
                }
                
                if DebugModel.shared.debugMode {
                    RoomDebugDetailsSection(room: room)
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
                                try await container.leaveChild(room.roomId)
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

