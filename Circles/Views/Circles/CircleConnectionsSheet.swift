//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleConnectionsSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/18/20.
//

import SwiftUI
import Matrix

struct CircleConnectionsSheet: View {
    @ObservedObject var space: CircleSpace
    @Environment(\.presentationMode) var presentation
    @State var roomToLeave: Matrix.Room? = nil
    @State var showConfirmLeave = false
    
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            Spacer()
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .fontWeight(.bold)
            }
        }
    }
    
    func leaveRoom() async throws {
        if let room = roomToLeave {
            try await space.leaveChildRoom(room.roomId)
            roomToLeave = nil
        }
    }
    
    var body: some View {
        VStack() {
            //buttonBar
            
            Text("People I am following")
                .font(.title2)
                .fontWeight(.bold)
            
            List {
                let rooms = space.rooms.filter { $0.roomId != space.wall?.roomId }
                ForEach(rooms) { room in
                    let user = space.session.getUser(userId: room.creator)
                    //PersonsCircleRow(room: room)
                    HStack {
                        Image(uiImage: room.avatar ?? UIImage())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .onAppear {
                                room.updateAvatarImage()
                            }

                        VStack(alignment: .leading) {
                            Text(user.displayName ?? user.userId.username)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(room.name ?? "(unnamed)")

                        }
                    }
                    //.padding()
                    .contextMenu {
                        Button(role: .destructive, action: {
                            showConfirmLeave = true
                            roomToLeave = room
                        }) {
                            Label("Unfollow", systemImage: "xmark.bin")
                        }
                    }
                }

            }
            // FIXME: Show a confirmation dialog
            .confirmationDialog("Confirm Unfollow",
                                isPresented: $showConfirmLeave,
                                presenting: roomToLeave,
                                actions: {room in
                                    AsyncButton(role: .destructive, action: {
                                        try await space.leaveChildRoom(room.roomId)
                                    }) {
                                        Label("Yes, unfollow them", systemImage: "xmark.bin")
                                    }
                                }, message: {room in
                                    Text("Do you really want to unfollow \(room.name ?? "this timeline")?")
                                })
            
            Spacer()

        }
        .padding(5)
    }
}

/*
struct CircleConnectionsSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleConnectionsSheet()
    }
}
*/
