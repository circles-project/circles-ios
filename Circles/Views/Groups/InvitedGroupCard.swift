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
    
    @State var blur = 20.0
    
    var body: some View {
        HStack(spacing: 1) {
            RoomAvatar(room: room, avatarText: .roomInitials)
                //.overlay(Circle().stroke(Color.primary, lineWidth: 2))
                .scaledToFill()
                .frame(width: 120, height: 120)
                .blur(radius: blur)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .onTapGesture {
                    if blur >= 5 {
                        blur -= 5
                    }
                }
            
            VStack(alignment: .leading) {
                Text(room.name ?? "(unnamed group)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("From:")
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
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
            // Check to see if we have any connection to the person who sent this invitation
            // In that case we don't need to blur the room avatar
            let commonRooms = container.session.rooms.values.filter { $0.joinedMembers.contains(user.userId) }
            
            if !commonRooms.isEmpty {
                self.blur = 0
            }
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
