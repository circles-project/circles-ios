//
//  ChatSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/26/24.
//

import SwiftUI
import PhotosUI
import Matrix

struct ChatSettingsView: View {
    @ObservedObject var room: Matrix.Room
    
    @Environment(\.presentationMode) var presentation

    @State var newAvatarImageItem: PhotosPickerItem?
    
    @State var showConfirmLeave = false
    @State var showInviteSheet = false
    @State var showShareSheet = false
    
    let users: [UserId]
    let admins: [UserId]
    let mods: [UserId]
    let members: [UserId]
    
    init(room: Matrix.Room) {
        self.room = room
        
        self.users = room.joinedMembers
        self.admins = users.filter { userId in
            room.getPowerLevel(userId: userId) >= 100
        }
        self.mods = users.filter { userId in
            let power = room.getPowerLevel(userId: userId)
            return power < 100 && power >= 50
        }
        self.members = users.filter { userId in
            room.getPowerLevel(userId: userId) < 50
        }
    }
    
    @ViewBuilder
    var generalSection: some View {
        Section("General") {
            NavigationLink(destination: RoomRenameView(room: room)) {
                Text("Group name")
                    .badge(abbreviate(room.name))
            }
            
            HStack {
                Text("Cover image")
                Spacer()
                
                if room.iCanChangeState(type: M_ROOM_AVATAR) {
                    PhotosPicker(selection: $newAvatarImageItem, matching: .images) {
                        RoomAvatarView(room: room, avatarText: .none)
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
                    RoomAvatarView(room: room, avatarText: .none)
                        .frame(width: 80, height: 80)
                }
            }
            
            let creator = room.session.getUser(userId: room.creator)
            Text("Created by")
                .badge(creator.displayName ?? creator.userId.stringValue)
            
            NavigationLink(destination: RoomTopicEditorView(room: room)) {
                Text("Topic")
                    .badge(room.topic ?? "(none)")
            }
            
            if DebugModel.shared.debugMode {
                Text("Matrix roomId")
                    .badge(room.roomId.stringValue)
            }
            
        }
    }
        
    @ViewBuilder
    var sharingSection: some View {
        if room.joinRule == .knock,
           let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/chat/\(room.roomId.stringValue)")
        {
            Section("Sharing") {
                 if let qr = qrCode(url: url) {
                     HStack {
                         Text("QR code")
                         Spacer()
                         Button(action: {
                             showShareSheet = true
                         }) {
                             Image(uiImage: qr)
                                 .resizable()
                                 .scaledToFill()
                                 .frame(width: 80, height: 80)
                         }
                         .sheet(isPresented: $showShareSheet) {
                             RoomShareSheet(room: room, url: url)
                         }
                     }
                 }
                HStack {
                    Text("Link")
                    Spacer()
                    ShareLink("Share", item: url)
                }
            }
        }
    }
    

    
    var body: some View {
        Form {
            generalSection
            
            sharingSection
            
            if !admins.isEmpty {
                RoomMembersSection(title: "Administrators",
                                   users: admins,
                                   room: room)
            }
            
            if !mods.isEmpty {
                RoomMembersSection(title: "Moderators",
                                   users: mods,
                                   room: room)
            }
            
            if !members.isEmpty {
                RoomMembersSection(title: "Regular Members",
                                   users: members,
                                   room: room)
            }
            
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
                    Label("Invite new members", systemImage: SystemImages.personCropCircleBadgePlus.rawValue)
                }
                .sheet(isPresented: $showInviteSheet) {
                    RoomInviteSheet(room: room)
                }
            }
            
            let banned = room.bannedMembers
            if !banned.isEmpty {
                Section("Banned Members") {
                    ForEach(banned) { userId in
                        let user = room.session.getUser(userId: userId)
                        BannedRoomMemberRow(user: user, room: room)
                    }
                }
            }
            
            if DebugModel.shared.debugMode {
                RoomDebugDetailsSection(room: room)
            }
            
            if room.iCanChangeState(type: M_ROOM_POWER_LEVELS) {
                Section("User Permissions") {
                    RoomDefaultPowerLevelPicker(room: room)
                }
            }
            
            Section("Danger Zone") {
                
                let powerUsers = admins + mods
                // Are we the only user with mod powers?
                let iAmTheOnlyMod: Bool = powerUsers.contains(room.session.creds.userId) && powerUsers.count == 1

                
                Button(role: .destructive, action: {
                    self.showConfirmLeave = true
                }) {
                    Label("Leave group", systemImage: SystemImages.xmark.rawValue)
                        .foregroundColor(.red) // This is necessary because setting `role: .destructive` only changes the text color, not the icon 🙄
                }
                .confirmationDialog(
                    "Confirm leaving group",
                    isPresented: $showConfirmLeave,
                    actions: {
                        if iAmTheOnlyMod {
                            // If so then we can't just up and leave, or the room will become unmoderated
                            
                            AsyncButton(role: .destructive, action: {
                                try await room.close(kickEveryone: false)
                            }) {
                                Label("Archive the group and preserve old posts", systemImage: "archivebox")
                            }
                            
                            AsyncButton(role: .destructive, action: {
                                try await room.close(kickEveryone: true)
                            }) {
                                Label("Remove all members and delete the group", systemImage: SystemImages.trash.rawValue)
                            }
                            
                        } else {
                            // Otherwise no worries we can leave whenever without a problem
                            
                            AsyncButton(role: .destructive, action: {
                                
                                // FIXME: Sanity check - Are we leaving the room unmoderated?  Don't do that.
                                
                                try await room.leave()
                                self.presentation.wrappedValue.dismiss()
                            }) {
                                Text("Leave \"\(room.name ?? "this group")\"")
                            }
                        }
                    },
                    message: {
                        if iAmTheOnlyMod {
                            Text("You are the only user with moderator power. If you leave, the chat will be closed to new posts.")
                        } else {
                            Text("Really leave \(room.name ?? "this chat")?")
                        }
                    }
                )
                
            }
        }
        .navigationTitle("Chat Settings")
    }
}

