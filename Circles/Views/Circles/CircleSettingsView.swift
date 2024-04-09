//
//  CircleSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import PhotosUI
import Matrix

struct CircleSettingsView: View {
    @ObservedObject var space: CircleSpace
    
    @AppStorage("debugMode") var debugMode: Bool = false

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
            Text("Circle name")
                .badge(space.name ?? "(none)")
            
            HStack {
                Text("Cover image")
                Spacer()
                
                PhotosPicker(selection: $newAvatarImageItem, matching: .images) {
                    RoomAvatarView(room: space.wall ?? space, avatarText: .none)
                        .clipShape(Circle())
                        .frame(width: 80, height: 80)
                }
                .buttonStyle(.plain)
                .onChange(of: newAvatarImageItem) { _ in
                    Task {
                        if let data = try? await newAvatarImageItem?.loadTransferable(type: Data.self) {
                            
                            if let img = UIImage(data: data) {
                                //try await space.setAvatarImage(image: img)
                                if let wall = space.wall {
                                    try await wall.setAvatarImage(image: img)
                                }
                            }
                        }
                    }
                }
            }
            
            if debugMode {
                Text("Space roomId")
                    .badge(space.roomId.stringValue)
            }
            
            if let wall = space.wall,
               wall.joinRule == .knock,
               let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/timeline/\(wall.roomId.stringValue)")
            {
                
                if debugMode {
                    Text("Wall roomId")
                        .badge(wall.roomId.stringValue)
                }
                
                HStack {
                    Text("Link")
                    Spacer()
                    ShareLink("Share", item: url)
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
                            RoomShareSheet(room: wall, url: url)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var followingSection: some View {
        let myUserId = space.session.creds.userId
        let timelines = space.rooms.values.filter { $0.creator != myUserId }
        Section("Timelines I'm Following (\(timelines.count))") {
            ForEach(timelines) { room in
                let user = space.session.getUser(userId: room.creator)
                CircleFollowingRow(space: space, room: room, user: user)
            }
        }
    }
    
    @ViewBuilder
    var followersSection: some View {
        if let wall = space.wall {
            let myUserId = wall.session.creds.userId
            let followers = wall.joinedMembers.filter { $0 != myUserId }
            Section("My Followers (\(followers.count))") {
                ForEach(followers) { userId in
                    let user = wall.session.getUser(userId: userId)
                    NavigationLink(destination: RoomMemberDetailView(user: user, room: wall)) {
                        RoomMemberRow(user: user, room: wall)
                    }
                }
                Button(action: {
                    self.showInviteSheet = true
                }) {
                    Label("Invite more followers", systemImage: "person.badge.plus")
                }
                .sheet(isPresented: $showInviteSheet) {
                    RoomInviteSheet(room: wall, title: "Invite followers")
                }
            }
            
            let invited = wall.invitedMembers
            if !invited.isEmpty {
                Section("Invited Followers") {
                    ForEach(invited) { userId in
                        let user = wall.session.getUser(userId: userId)
                        
                        RoomInvitedMemberRow(room: wall, user: user)
                    }
                }
            }
        }
    }
    

    var body: some View {
        VStack {
            Form {
                generalSection
                
                followingSection
                
                followersSection
                
                if let wall = space.wall,
                   debugMode
                {
                    RoomDebugDetailsSection(room: wall)
                }
            }
        }
        .navigationTitle("Settings for \(space.name ?? "this circle")")
    }
}

