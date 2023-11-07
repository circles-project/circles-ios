//
//  GroupSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import PhotosUI
import Matrix

struct GroupSettingsView: View {
    @ObservedObject var room: GroupRoom
    
    @AppStorage("debugMode") var debugMode: Bool = false

    @State var newAvatarImageItem: PhotosPickerItem?
    
    @State var showConfirmLeave = false
    @State var showInviteSheet = false
    
    @ViewBuilder
    var generalSection: some View {
        Section("General") {
            Text("Group name")
                .badge(room.name ?? "(none)")
            
            HStack {
                Text("Cover image")
                Spacer()
                
                if room.iCanChangeState(type: M_ROOM_AVATAR) {
                    PhotosPicker(selection: $newAvatarImageItem, matching: .images) {
                        RoomAvatar(room: room, avatarText: .none)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.plain)
                    .onChange(of: newAvatarImageItem) { _ in
                        Task {
                            if let data = try? await newAvatarImageItem?.loadTransferable(type: Data.self) {
                                
                                if let img = UIImage(data: data) {
                                    try await room.setAvatarImage(image: img)
                                }
                            }
                        }
                    }
                } else {
                    RoomAvatar(room: room, avatarText: .none)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 80, height: 80)
                }
            }
            
            Text("Topic")
                .badge(room.topic ?? "(none)")
            
            if debugMode {
                Text("Matrix roomId")
                    .badge(room.roomId.stringValue)
            }
            
            if let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/timeline/\(room.roomId.stringValue)")
            {
                 HStack {
                     Text("Link")
                     Spacer()
                     ShareLink("Share", item: url)
                 }
                 
                 if let qr = qrCode(url: url) {
                     HStack {
                         Text("QR code")
                         Spacer()
                         Image(uiImage: qr)
                             .resizable()
                             .scaledToFill()
                             .frame(width: 80, height: 80)
                     }
                 }
            }
        }
    }
    
    struct MembersSection: View {
        var title: String
        var users: [UserId]
        var room: Matrix.Room
        
        var body: some View {
            Section(title) {
                ForEach(users) { userId in
                    let user = room.session.getUser(userId: userId)
                    RoomMemberRow(user: user, room: room)
                }
            }
        }
    }
    
    var body: some View {
        Form {
            generalSection
            
            let users = room.joinedMembers
            let admins = users.filter { userId in
                room.getPowerLevel(userId: userId) >= 100
            }
            let mods = users.filter { userId in
                let power = room.getPowerLevel(userId: userId)
                return power < 100 && power >= 50
            }
            let members = users.filter { userId in
                room.getPowerLevel(userId: userId) < 50
            }
            
            if !admins.isEmpty {
                MembersSection(title: "Administrators",
                               users: admins,
                               room: room)
            }
            
            if !mods.isEmpty {
                MembersSection(title: "Moderators",
                               users: mods,
                               room: room)
            }
            
            MembersSection(title: "Regular Members",
                           users: members,
                           room: room)
            
            let invited = room.invitedMembers
            if !invited.isEmpty {
                Section("Invited Members") {
                    ForEach(invited) { userId in
                        let user = room.session.getUser(userId: userId)
                        RoomInvitedMemberRow(room: room, user: user)
                    }
                }
            }
            
            if room.iCanInvite {
                Button(action: {
                    self.showInviteSheet = true
                }) {
                    Label("Invite new members", systemImage: "person.crop.circle.badge.plus")
                }
                .sheet(isPresented: $showInviteSheet) {
                    RoomInviteSheet(room: room)
                }
            }
            
            Section("Danger Zone") {
                Button(role: .destructive, action: {
                    self.showConfirmLeave = true
                }) {
                    Label("Leave group", systemImage: "xmark")
                        .foregroundColor(.red) // This is necessary because setting `role: .destructive` only changes the text color, not the icon 🙄
                }
                .confirmationDialog(
                    "Confirm leaving group",
                    isPresented: $showConfirmLeave
                ) {
                    AsyncButton(role: .destructive, action: {
                        
                        // FIXME: Sanity check - Are we leaving the room unmoderated?  Don't do that.
                        
                        try await room.leave()
                    }) {
                        Text("Leave \"\(room.name ?? "this group")\"")
                    }
                }
            }
        }
        .navigationTitle("Group Settings")
    }
}

