//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  InvitationsScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 3/3/21.
//

import SwiftUI


struct InvitationsView: View {
    var store: LegacyStore
    @State var invitedRooms: [InvitedRoom] = []
    @State var selectedRoom: MatrixRoom?
    @State var showAcceptSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            //var invitedRooms = store.getInvitedRooms()
            if !invitedRooms.isEmpty {
                // I think having this be a ScrollView is part of what makes it render weird on the screen
                // Maybe if we make this View non-scrollable, we can just always wrap it in a ScrollView whenever we need to use it
                // Then we get the scrolling at the appropriate place on the screen, instead of a tiny little 300px area where we have to scroll through all the invitations
                //ScrollView {
                    ForEach(invitedRooms) { room in
                        InvitationCard(room: room, selectedRoom: $selectedRoom, showAcceptSheet: $showAcceptSheet)
                    }
                    .onDelete(perform: { indexSet in
                        let dgroup = DispatchGroup()
                        for index in indexSet {
                            print("Need to delete \(index) -- That's \(invitedRooms[index].id)")
                            let room = invitedRooms[index]
                            dgroup.enter()
                            store.leaveRoom(roomId: room.id) { success in
                                dgroup.leave()
                            }
                        }
                        
                        dgroup.notify(queue: .main) {
                            invitedRooms.remove(atOffsets: indexSet)
                        }
                    })
                //}
            } else {
                Text("No new invitations at this time")
            }
        }
        .onAppear {
            invitedRooms = store.getInvitedRooms()
        }
        //.sheet(isPresented: $showAcceptSheet) {
        .sheet(item: $selectedRoom) { room in
            VStack {
                //if let room = self.selectedRoom {
                    InvitationAcceptSheet(store: store, room: room)
                //}
                //else {
                //    Text("Something went wrong")
                //}
            }
        }
    }
}

struct InvitationsScreen: View {
    var store: LegacyStore
    
    var body: some View {
        ScrollView {
            VStack {
                Label("New Invitations", systemImage: "envelope.open.fill")
                    .font(.title2)
                    //.fontWeight(.bold)
                    .padding()

                InvitationsView(store: store)
                    .navigationBarTitle(Text("Invitations"))
                    .padding()

                Spacer()
            }
        }
    }
}

/*
struct InvitationsScreen_Previews: PreviewProvider {
    static var previews: some View {
        InvitationsScreen()
    }
}
*/
