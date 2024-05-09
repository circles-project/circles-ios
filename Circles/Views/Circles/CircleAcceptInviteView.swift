//
//  CircleAcceptInviteView.swift
//  Circles
//
//  Created by Charles Wright on 5/2/24.
//

import SwiftUI
import Matrix

struct CircleAcceptInviteView: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    @ObservedObject var container: ContainerRoom<CircleSpace>

    
    @State var selectedCircles: Set<CircleSpace> = []
    @State var inviteToFollowMe = true

    
    var body: some View {
        ScrollView {
            VStack {
                Text("Where would you like to see posts from \(user.displayName ?? user.userId.username)'s \(room.name ?? "") timeline?")
                
                Text("Choose one or more of your circles")
                    .padding()
                
                CirclePicker(selected: $selectedCircles)
                
                Toggle(isOn: $inviteToFollowMe) {
                    Text("Invite this user to follow me")
                }
                .frame(maxWidth: 300)
                .padding()
                
                AsyncButton(action: {
                    // It's possible that we are already in this room
                    let joinedRoomIds = try await room.session.getJoinedRoomIds()
                    if joinedRoomIds.contains(room.roomId) {
                        print("No need to accept invite - we are already in \(room.roomId)")
                    } else {
                        print("Accepting invite to join \(room.roomId)")
                        try await room.accept()
                    }
                    for circle in selectedCircles {
                        print("Adding \(room.name ?? "new timeline") to circle \(circle.wall?.name ?? circle.roomId.stringValue)")
                        try await circle.addChild(room.roomId)
                        if let wall = circle.wall,
                           inviteToFollowMe == true,
                           !wall.joinedMembers.contains(user.userId)
                        {
                            print("Inviting user \(user.userId) to follow me in \(circle.wall?.name ?? circle.roomId.stringValue)")
                            try await wall.invite(userId: user.userId)
                        } else {
                            print("Not inviting user \(user.userId) to follow me in \(circle.wall?.name ?? circle.roomId.stringValue)")
                        }
                    }
                }) {
                    Label("Accept invite and follow", systemImage: "thumbsup")
                }
                .disabled(selectedCircles.isEmpty)
                .padding()
            }
            .padding()
        }
    }
}

