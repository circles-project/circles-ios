//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomMembersSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/10/20.
//

import SwiftUI
import Matrix

struct RoomMembersSheet: View {
    @ObservedObject var room: Matrix.Room
    var title: String? = nil
    @Environment(\.presentationMode) var presentation

    @State var members: [Matrix.User] = []

    @State var showInviteSheet = false
    @State var currentToBeRemoved: [Matrix.User] = []
    @State var showConfirmRemove = false
    
    @State var currentMembers: [Matrix.User] = []
    @State var invitedMembers: [Matrix.User] = []
    
    /*
    init(room: MatrixRoom) {
        self.room = room
        //self.currentMembers = room.joinedMembers
        //self.invitedMembers = room.invitedMembers
    }
    */
    
    var buttonBar: some View {
        HStack {
            /*
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            */
            
            Spacer()
            
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }){
                Text("Done")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding()
        }
    }
    
    func kickUsers() async throws {
        for user in self.currentToBeRemoved {
            try await room.kick(userId: user.userId)
        }
    }
    
    func banUsers() async throws {
        for user in self.currentToBeRemoved {
            try await room.ban(userId: user.userId)
        }
    }
    
    var currentMemberSection: some View {
        Section(header: Text("Current")) {
            ForEach(room.joinedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                RoomMemberRow(user: user, room: room)
                    .actionSheet(isPresented: $showConfirmRemove) {
                        return ActionSheet(title: Text("Remove Users?"),
                                    message: Text("Are you sure you want to remove \(currentToBeRemoved.count) user(s)?"),
                                    buttons: [
                                        .default(Text("Kick Them Out")) {
                                            //kickUsers()
                                            currentMembers.removeAll(where: {u in
                                                self.currentToBeRemoved.contains(u)
                                            })
                                            //current = room.joinedMembers
                                            self.currentToBeRemoved.removeAll()
                                        },
                                        .default(Text("Ban Them")) {
                                            //banUsers()
                                            currentMembers.removeAll(where: {u in
                                                self.currentToBeRemoved.contains(u)
                                            })
                                            self.currentToBeRemoved.removeAll()
                                        },
                                        .cancel() {
                                            self.currentToBeRemoved.removeAll()
                                        }
                                    ])
                    }
            }
            .onDelete { indexes in
                for index in indexes {
                    self.currentToBeRemoved.append(currentMembers[index])
                }
                //self.showConfirmRemove = true
                currentMembers.remove(atOffsets: indexes)
            }
        }
    }
    
    var invitedMemberSection: some View {
        Section(header: Text("Invited")) {
            ForEach(room.invitedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                RoomMemberRow(user: user, room: room)
            }
        }
    }
    
    var bannedMemberSection: some View {
        Section(header: Text("Banned")) {
            ForEach(room.bannedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                RoomMemberRow(user: user, room: room)
            }
        }
    }
    
    var body: some View {
        VStack {
            
            //buttonBar
            
            Text(title ?? "Followers for \(room.name ?? "this room")")
                .font(.headline)
                .fontWeight(.bold)
                .padding(10)
            
            Spacer()
            
            VStack(alignment: .leading) {
                //let haveModPowers = room.amIaModerator()

                List {
                    currentMemberSection

                    if !room.invitedMembers.isEmpty {
                        invitedMemberSection
                    }

                    if !room.bannedMembers.isEmpty {
                        bannedMemberSection
                    }
                }
            }

        }

    }
}

