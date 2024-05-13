//
//  InvitedCircleCard.swift
//  Circles
//
//  Created by Charles Wright on 7/19/23.
//

import SwiftUI
import Matrix

struct InvitedCircleCard: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    @ObservedObject var container: ContainerRoom<CircleSpace>
    
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @State var showAcceptSheet = false
    
    @State var blur = 20.0
    
    var body: some View {
        HStack(spacing: 1) {
            RoomAvatarView(room: room, avatarText: .none)
                //.overlay(Circle().stroke(Color.primary, lineWidth: 2))
                .clipShape(Circle())
                .frame(width: 140, height: 140)
                .scaledToFit()
                .blur(radius: blur)
                .onTapGesture {
                    if blur >= 5 {
                        blur -= 5
                    }
                }
                .padding(.horizontal, 5)
            
            VStack(alignment: .leading) {
                Text(room.name ?? "(unnamed circle)")
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if debugMode {
                    Text(room.roomId.stringValue)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

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
                        //Label("Reject", systemImage: "hand.thumbsdown.fill")
                        Text("Reject")
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.showAcceptSheet = true
                    }) {
                        //Label("Accept", systemImage: "hand.thumbsup.fill")
                        Text("Accept")
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(6)
                    }
                    .sheet(isPresented: $showAcceptSheet) {
                        CircleAcceptInviteView(room: room, user: user, container: container)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: InvitedCircleDetailView(room: room, user: user)) {
                        //Label("Info", systemImage: "ellipsis.circle")
                        Text("Info")
                            //.labelStyle(.iconOnly)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.accentColor))
                    }
                }
                .padding(.top, 5)
                .padding(.horizontal, 10)

                if debugMode {
                    let joinedRoomIds = room.session.rooms.values.compactMap { $0.roomId }
                    if joinedRoomIds.contains(room.roomId) {
                        Text("Room is already joined")
                    } else {
                        Text("New room")
                    }
                }
            }
        }
        .onAppear {
            // Check to see if we have any connection to the person who sent this invitation
            // In that case we don't need to blur the room avatar
            let commonRooms = container.session.rooms.values.filter { $0.joinedMembers.contains(user.userId) }
            
            if !commonRooms.isEmpty {
                self.blur = 0
            }
            
            // Check to see if this is maybe a stale/stuck invitation
            print("INVITE Checking \(room.roomId) for stuck invitations")
            let circles = container.rooms.values
            if let existingCircle = circles.first(where: {$0.children.contains(room.roomId) || $0.rooms[room.roomId] != nil}) {
                // Somehow we've already joined this one
                print("INVITE Room \(room.roomId) is already followed in circle \(existingCircle.name ?? existingCircle.roomId.stringValue)")
                Task {
                    try await container.session.deleteInvitedRoom(roomId: room.roomId)
                }
            } else {
                print("INVITE Room \(room.roomId) is not already followed")
            }
        }
    }
}

/*
struct InvitedCircleCard_Previews: PreviewProvider {
    static var previews: some View {
        InvitedCircleCard()
    }
}
*/
