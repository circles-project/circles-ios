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
    @AppStorage("blurUnknownUserPicture") var blurUnknownUserPicture = true
    @State var blur = 10.0
    
    var body: some View {
        HStack(spacing: 1) {
            VStack {
                RoomAvatarView(room: room, avatarText: .oneLetter)
                //.overlay(Circle().stroke(Color.primary, lineWidth: 2))
                    .frame(width: 80, height: 80)
                    .blur(radius: blurUnknownUserPicture ? blur : 0)
                    .onTapGesture {
                        if blur >= 5 {
                            blur -= 5
                        }
                    }
                    .padding(.horizontal, 5)
                Spacer()
            }
            
            VStack(alignment: .leading) {
                Text(room.name ?? "(unnamed group)")
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        if let name = user.displayName {
                            Text(name)
                                .lineLimit(1)
                            Text(user.userId.stringValue)
                                .lineLimit(1)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else {
                            Text(user.userId.stringValue)
                                .lineLimit(1)
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    
                    AsyncButton(role: .destructive, action: {
                        try await room.reject()
                    }) {
                        Text("Reject")
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 6).stroke(Color.red))
                    }
                    
                    Spacer()
                    
                    AsyncButton(action: {
                        try await room.accept()
                        try await container.addChild(room.roomId)
                    }) {
                        Text("Accept")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: InvitedGroupDetailView(room: room, user: user)) {
                        Image(systemName: SystemImages.ellipsisCircle.rawValue)
                            .imageScale(.large)
                            .padding(10)
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
