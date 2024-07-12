//
//  CircleSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import PhotosUI
import Matrix

struct SingleTimelineSettingsView: View {
    @ObservedObject var room: Matrix.Room
    
    @State var newAvatarImageItem: PhotosPickerItem?

    @State var showConfirmUnfollow = false
    @State var roomToUnfollow: Matrix.Room?

    @State var showInviteSheet = false
    @State var showShareSheet = false
    
    @State var showConfirmResend = false
    @State var showConfirmCancelInvite = false
    
    @ViewBuilder
    var generalSection: some View {
        Section("General") {
            
            let creator = room.session.getUser(userId: room.creator)
            Text("Owner")
                .badge(creator.displayName ?? creator.userId.stringValue)
            
            NavigationLink(destination: CircleRenameView(room: room)) {
                Text("Circle name")
                    .badge(abbreviate(room.name))
            }
            .disabled(!room.iCanChangeState(type: M_ROOM_NAME))
            
            HStack {
                Text("Cover image")
                Spacer()
                
                PhotosPicker(selection: $newAvatarImageItem, matching: .images) {
                    RoomAvatarView(room: room, avatarText: .none)
                        .clipShape(Circle())
                        .frame(width: 80, height: 80)
                }
                .disabled(!room.iCanChangeState(type: M_ROOM_AVATAR))
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
           let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/timeline/\(room.roomId.stringValue)")
        {
            Section("Sharing") {
                if DebugModel.shared.debugMode {
                    Text("roomId")
                        .badge(room.roomId.stringValue)
                }
                
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
    
    @ViewBuilder
    var followersSection: some View {
        
        let myUserId = room.session.creds.userId
        let followers = room.joinedMembers.filter { $0 != myUserId }
        Section("My Followers (\(followers.count))") {
            ForEach(followers) { userId in
                let user = room.session.getUser(userId: userId)
                NavigationLink(destination: RoomMemberDetailView(user: user, room: room)) {
                    RoomMemberRow(user: user, room: room)
                }
            }
            Button(action: {
                self.showInviteSheet = true
            }) {
                Label("Invite more followers", systemImage: SystemImages.personCropCircleBadgePlus.rawValue)
            }
            .sheet(isPresented: $showInviteSheet) {
                RoomInviteSheet(room: room, title: "Invite followers")
            }
        }
        
        let invited = room.invitedMembers
        if !invited.isEmpty {
            Section("Invited Followers") {
                ForEach(invited) { userId in
                    let user = room.session.getUser(userId: userId)
                    
                    RoomInvitedMemberRow(room: room, user: user)
                }
            }
        }
        
        let banned = room.bannedMembers
        if !banned.isEmpty {
            Section("Banned Followers") {
                ForEach(banned) { userId in
                    let user = room.session.getUser(userId: userId)
                    BannedRoomMemberRow(user: user, room: room)
                }
            }
        }
            
    }
    

    var body: some View {
        VStack {
            Form {
                generalSection
                
                sharingSection
                                
                followersSection
                
                if DebugModel.shared.debugMode
                {
                    RoomDebugDetailsSection(room: room)
                }
                
                if room.iCanChangeState(type: M_ROOM_POWER_LEVELS)
                {
                    Section("Follower Permissions") {
                        RoomDefaultPowerLevelPicker(room: room)
                    }
                }
            }
        }
        .navigationTitle("Settings for \(room.name ?? "this timeline")")
    }
}
