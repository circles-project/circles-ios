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
    @State var selectedCircles: Set<CircleSpace> = []
    
    @State var blur = 20.0
    
    var body: some View {
        HStack(spacing: 1) {
            RoomAvatar(room: room, avatarText: .none)
                //.overlay(Circle().stroke(Color.primary, lineWidth: 2))
                .frame(width: 180, height: 180)
                .scaledToFit()
                .padding(-15)
                .blur(radius: blur)
                .clipShape(Circle())
                .onTapGesture {
                    if blur >= 5 {
                        blur -= 5
                    }
                }
            
            VStack(alignment: .leading) {
                Text(room.name ?? "(unnamed circle)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if debugMode {
                    Text(room.roomId.stringValue)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

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
                    
                    Button(action: {
                        self.showAcceptSheet = true
                    }) {
                        Label("Accept", systemImage: "hand.thumbsup.fill")
                    }
                    .sheet(isPresented: $showAcceptSheet) {
                        ScrollView {
                            VStack {
                                Text("Where would you like to follow updates from \(room.name ?? "this friend's timeline")?")
                                
                                Text("You can choose one or more of your circles")
                                
                                CirclePicker(container: container, selected: $selectedCircles)
                                
                                AsyncButton(action: {
                                    try await room.accept()
                                    for circle in selectedCircles {
                                        try await circle.addChild(room.roomId)
                                    }
                                }) {
                                    Label("Accept invite and follow", systemImage: "thumbsup")
                                }
                                .disabled(selectedCircles.isEmpty)
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: InvitedCircleDetailView(room: room, user: user)) {
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
