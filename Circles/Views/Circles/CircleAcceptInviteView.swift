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

    @Environment(\.presentationMode) var presentation
    
    @State var selectedCircles: Set<CircleSpace> = []
    @State var inviteToFollowMe = true
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Where would you like to see posts from")
                    .font(.headline)
                    .padding()
                
                HStack(alignment: .center) {
                    RoomAvatarView(room: room, avatarText: .none)
                        .frame(width: 65, height: 65)
                    VStack(alignment: .leading) {
                        Text(room.name ?? "")
                            .fontWeight(.bold)
                        UserNameView(user: user)
                        Text(user.userId.stringValue)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Choose one or more of your circles to continue")
                            .padding(.top)
                        
                        CirclePicker(selected: $selectedCircles)
                    }
                    .frame(maxWidth: 350)
                    
                    Spacer()
                }
                
                let selectedButNotFollowedCircles = selectedCircles.filter({ space in
                    guard let wall = space.wall
                    else { return false }
                    
                    if wall.joinedMembers.contains(user.userId) {
                        return false
                    } else {
                        return true
                    }
                })
                
                if !selectedButNotFollowedCircles.isEmpty {
                    Toggle(isOn: $inviteToFollowMe) {
                        let count = selectedButNotFollowedCircles.count
                        if count > 1 {
                            Text("Invite this user to follow my timelines for these circles")
                        } else if count > 0 {
                            Text("Invite this user to follow my timeline for this circle")
                        } else {
                            Text("Invite this user to follow me")
                        }
                    }
                    .tint(.orange)
                    .frame(maxWidth: 300)
                    .padding()
                }
                
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
                
                Button(role: .destructive, action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
                .padding()
            }
            .padding()
        }
    }
}

