//
//  InvitedGroupCard.swift
//  Circles
//
//  Created by Charles Wright on 8/9/23.
//

import SwiftUI
import Matrix

struct InvitedGroupCard: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    @ObservedObject var container: ContainerRoom<GroupRoom>
    
    var body: some View {
        HStack(spacing: 1) {
            RoomAvatar(room: room, avatarText: .roomInitials)
                //.overlay(Circle().stroke(Color.primary, lineWidth: 2))
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
            
            VStack(alignment: .leading) {
                Text(room.name ?? "(unnamed group)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("From:")
                HStack(alignment: .top) {
                    VStack {
                        if let name = user.displayName {
                            Text(name)
                            Text(user.userId.stringValue)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else {
                            Text(user.userId.stringValue)
                        }
                    }
                }
                
                HStack {
                    AsyncButton(role: .destructive, action: {
                        try await room.reject()
                    }) {
                        Label("Reject", systemImage: "hand.thumbsdown.fill")
                    }
                    
                    Spacer()
                    
                    AsyncButton(action: {
                        try await room.accept()
                        try await container.addChildRoom(room.roomId)
                    }) {
                        Label("Accept", systemImage: "hand.thumbsup.fill")
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: InvitedGroupDetailView(room: room, user: user)) {
                        Label("Details", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)

                    }
                }
                .padding(.top, 5)
                .padding(.trailing, 10)
            }
        }
        .onAppear {
             room.updateAvatarImage()
        }
    }
}

/*
struct InvitedGroupCard_Previews: PreviewProvider {
    static var previews: some View {
        InvitedGroupCard()
    }
}
*/
