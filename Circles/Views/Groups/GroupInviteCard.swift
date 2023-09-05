//
//  GroupInviteCard.swift
//  Circles
//
//  Created by Charles Wright on 4/15/23.
//

import Foundation
import SwiftUI

import Matrix

struct GroupInviteCard: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    @ObservedObject var container: ContainerRoom<GroupRoom>
    
    var body: some View {
        VStack(alignment: .center) {
            
            Label("New Invitation!", systemImage: "envelope.open")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Image(uiImage: room.avatar ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                
                VStack(alignment: .leading) {
                    Text("\(room.name ?? "(unknown)")")
                        .fontWeight(.bold)
                    Text("From: \(user.displayName ?? "")")
                    Text(user.userId.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                //.padding(.leading)
            }
            
            HStack {
                Spacer()
                
                AsyncButton(role: .destructive, action: {
                    try await room.reject()
                }) {
                    Label("Reject", systemImage: "xmark.circle")
                }
                .padding(2)
                .frame(width: 120.0, height: 40.0)
                .buttonStyle(.bordered)
                
                Spacer()
                
                AsyncButton(action: {
                    let roomId = room.roomId
                    try await room.accept()
                    try await container.addChildRoom(roomId)
                }) {
                    Label("Accept", systemImage: "checkmark.circle")
                }
                .padding(2)
                .frame(width: 120.0, height: 40.0)
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 2)
                .foregroundColor(.background)
        )
        .padding(4)
        .onAppear {
            room.updateAvatarImage()
        }
    }
}
