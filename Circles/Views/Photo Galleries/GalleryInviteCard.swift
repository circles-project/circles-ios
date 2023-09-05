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
    @ObservedObject var container: ContainerRoom<GalleryRoom>
    
    @ViewBuilder
    var buttonRow: some View {
         HStack {
            Spacer()
            
             AsyncButton(role: .destructive, action: {
                try await room.reject()
            }) {
                Label("Reject", systemImage: "hand.thumbsdown.fill")
            }
            .padding(2)
            .frame(width: 120.0, height: 40.0)
            
            Spacer()
            
            AsyncButton(action: {
                let roomId = room.roomId
                try await room.accept()
                try await container.addChildRoom(roomId)
            }) {
                Label("Accept", systemImage: "hand.thumbsup.fill")
            }
            .padding(2)
            .frame(width: 120.0, height: 40.0)
            
            Spacer()
        }
        //.buttonStyle(.bordered)
    
    }
    
    var body: some View {
        VStack(alignment: .leading) {
                
            RoomAvatar(room: room, avatarText: .roomName)
                .scaledToFill()
                //.frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text("\(room.name ?? "(unknown)")")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(alignment: .top) {
                Text("From:")

                Image(uiImage: user.avatar ?? UIImage(systemName: "person.circle")!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(user.displayName ?? user.userId.username)
                    Text(user.userId.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            buttonRow
        }
        .padding()
        .onAppear {
            room.updateAvatarImage()
            user.refreshProfile()
        }
    }
}
