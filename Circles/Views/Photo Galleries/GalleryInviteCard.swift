//  Copyright 2023 FUTO Holdings Inc
//
//  GalleryInviteCard.swift
//  Circles
//
//  Created by Charles Wright on 4/17/23.
//

import Foundation
import SwiftUI

import Matrix

struct GalleryInviteCard: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    var container: ContainerRoom<GalleryRoom>
    
    @State var roomAvatarBlur = 20.0
    @State var userAvatarBlur = 20.0
    
    @ViewBuilder
    var buttonRow: some View {
         HStack {
            Spacer()
            
             AsyncButton(role: .destructive, action: {
                try await room.reject()
            }) {
                Text("Reject")
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.red))
            }
            .padding(2)
            .frame(width: 120.0, height: 40.0)
            
            Spacer()
            
            AsyncButton(action: {
                let roomId = room.roomId
                try await room.accept()
                try await container.addChild(roomId)
            }) {
                Text("Accept")
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(6)
            }
            .padding(2)
            .frame(width: 120.0, height: 40.0)
            
            Spacer()
        }
        //.buttonStyle(.bordered)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
                
            RoomAvatarView(room: room, avatarText: .roomName)
                .scaledToFill()
                .frame(maxWidth: 400, maxHeight: 400)
                .blur(radius: roomAvatarBlur)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onTapGesture {
                    if roomAvatarBlur >= 5 {
                        roomAvatarBlur -= 5
                    }
                }
            
            HStack(alignment: .top) {
                Text("From:")

                UserAvatarView(user: user)
                    .frame(width: 40, height: 40)
                    .blur(radius: userAvatarBlur)
                    //.clipShape(Circle())
                    .onTapGesture {
                        if userAvatarBlur >= 5 {
                            userAvatarBlur -= 5
                        }
                    }
                
                VStack(alignment: .leading) {
                    Text(user.displayName ?? user.userId.username)
                    Text(user.userId.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            buttonRow
        }
        .frame(maxWidth: 400)
        .padding()
        .onAppear {
            // Check to see if we have any connection to the person who sent this invitation
            // In that case we don't need to blur the room avatar
            let commonRooms = container.session.rooms.values.filter { $0.joinedMembers.contains(user.userId) }
            
            if !commonRooms.isEmpty {
                self.userAvatarBlur = 0
                self.roomAvatarBlur = 0
            }
        }
    }
}
