//
//  GallerySettingsView.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import PhotosUI
import Matrix

struct GallerySettingsView: View {
    @ObservedObject var room: GalleryRoom
    var container: ContainerRoom<GalleryRoom>
    @Environment(\.presentationMode) var presentation

    @State var newAvatarImageItem: PhotosPickerItem?
    
    @State var showConfirmLeave = false
    @State var showInviteSheet = false
    @State var showShareSheet = false
    
    @ViewBuilder
    var generalSection: some View {
        Section("General") {
            NavigationLink(destination: RoomRenameView(room: room)) {
                Text("Gallery name")
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
            
            if DebugModel.shared.debugMode {
                Text("Matrix roomId")
                    .badge(room.roomId.stringValue)
            }
            
        }
    }
    
    @ViewBuilder
    var sharingSection: some View {
        Section("Sharing") {
            if let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/gallery/\(room.roomId.stringValue)")
            {
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
                Button(role: .destructive, action: {
                    self.showConfirmLeave = true
                }) {
                    Label("Leave gallery", systemImage: SystemImages.xmark.rawValue)
                        .foregroundColor(.red) // This is necessary because setting `role: .destructive` only changes the text color, not the icon 🙄
                }
                .confirmationDialog(
                    "Confirm leaving gallery",
                    isPresented: $showConfirmLeave
                ) {
                    AsyncButton(role: .destructive, action: {
                        
                        // FIXME: Sanity check - Are we leaving the room unmoderated?  Don't do that.
                        
                        try await container.leaveChild(room.roomId)
                        self.presentation.wrappedValue.dismiss()
                    }) {
                        Text("Leave \"\(room.name ?? "this gallery")\"")
                    }
                }
            }
        }
        .navigationTitle("Gallery Settings")
    }
}

