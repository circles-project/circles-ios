//
//  GroupMemberDetailView.swift
//  Circles
//
//  Created by Charles Wright on 12/14/23.
//

import SwiftUI
import Matrix

struct RoomMemberDetailView: View {
    @ObservedObject private var user: Matrix.User
    @ObservedObject private var room: Matrix.Room
    
    @EnvironmentObject private var session: CirclesApplicationSession
    
    @State private var selectedPower: Int
    
    @State private var showConfirmChangeSelf = false
    @State private var newSelfPowerLevel: Int?
    
    @State private var showConfirmIgnore = false
    @State private var showConfirmKick = false
    @State private var showConfirmBan = false
    
    @State private var isUserIgnored = false
    
    @State private var inviteRoom: Matrix.Room?
    
    private var userIsMe: Bool
    
    private let roles = [
        100: "Owner",
        50: "Moderator",
        0: "Poster",
        -1: "Read+React",
        -10: "Read Only",
    ].sorted(by: <)
    
    init(user: Matrix.User, room: Matrix.Room) {
        self.user = user
        self.room = room
        self.selectedPower = room.getPowerLevel(userId: user.userId)
        self.userIsMe = user.userId == room.session.creds.userId
        self.isUserIgnored = user.session.ignoredUserIds.contains(user.userId)
        
        print("My power = \(room.myPowerLevel) vs theirs = \(selectedPower)")
    }
    
    @ViewBuilder
    private var powerLevelSection: some View {
        let myPowerLevel = room.myPowerLevel
        
        Section("Power level") {
            
            // We need to prevent the user "accidentally" demoting themself if there's no one else to take over
            // See the .disabled() view modifier below
            let mods = room.joinedMembers.filter {
                room.getPowerLevel(userId: $0) >= 50
            }
            let iAmAMod = mods.contains(room.session.creds.userId)
        
            Picker("Role", selection: $selectedPower) {
                let availableLevels = CIRCLES_POWER_LEVELS.filter { level in
                    level.power <= myPowerLevel
                }
                ForEach(availableLevels) { level in
                    Text(level.description)
                        .tag(level)
                }
            }
            .disabled( iAmAMod && mods.count == 1 )
            .onChange(of: selectedPower) { newPower in
                print("Selected role changed: \(newPower)")
                if userIsMe {
                    // Chiggity check yo self before you wreck yo self
                    showConfirmChangeSelf = true
                    newSelfPowerLevel = newPower
                } else {
                    Task {
                        try await room.setPowerLevel(userId: user.userId, power: newPower)
                    }
                }
            }
            .confirmationDialog("Confirm",
                                isPresented: $showConfirmChangeSelf,
                                presenting: newSelfPowerLevel,
                                actions: { level in
                AsyncButton(role: .destructive, action: {
                    try await room.setPowerLevel(userId: room.session.creds.userId, power: level)
                }) {
                    Text("Change my power level")
                }
            },
                                message: { level in
                Label("WARNING: You are about to change your own power level.  This cannot be undone.", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
            } )
            
        }
    }
    
    @ViewBuilder
    private var moderationSection: some View {
        Section("Moderation") {
            setIgnoreButton
            
            if room.iCanKick {
                Button(role: .destructive, action: {
                    showConfirmKick = true
                }) {
                    if let name = room.name {
                        Label {
                            Text("Remove from \(name)")
                        } icon: {
                            Image(systemName: SystemImages.minusCircleFill.rawValue)
                                .foregroundColor(.red)
                        }
                            
                    } else {
                        Label {
                            Text("Remove this user")
                        } icon: {
                            Image(systemName: SystemImages.minusCircleFill.rawValue)
                                .foregroundColor(.red)
                        }
                    }
                }
                .disabled(userIsMe)
                .confirmationDialog("Confirm removing",
                                    isPresented: $showConfirmKick,
                                    actions: {
                    AsyncButton(role: .destructive, action: {
                        try await room.kick(userId: user.userId)
                    }) {
                        Text("Remove \(user.displayName ?? user.userId.stringValue)")
                    }
                })
            }
            
            if room.iCanBan {
                Button(role: .destructive, action: {
                    showConfirmBan = true
                }) {
                    if let name = room.name {
                        Label {
                            Text("Ban from \(name)")
                        } icon: {
                            Image(systemName: SystemImages.xmarkCircleFill.rawValue)
                                .foregroundColor(.red)
                        }
                            
                    } else {
                        Label {
                            Text("Ban this user")
                        } icon: {
                            Image(systemName: SystemImages.xmarkCircleFill.rawValue)
                                .foregroundColor(.red)
                        }
                    }
                }
                .disabled(userIsMe)
                .confirmationDialog("Confirm banning",
                                    isPresented: $showConfirmBan,
                                    actions: {
                    AsyncButton(role: .destructive, action: {
                        try await room.ban(userId: user.userId)
                    }) {
                        Text("Ban \(user.displayName ?? user.userId.stringValue)")
                    }
                })
            }
        }
    }
    
    @ViewBuilder
    private var circlesMenu: some View {
        Menu {
            let rooms = Array(session.timelines.rooms.values) //.sorted { $0.timestamp < $1.timestamp }
            ForEach(rooms) { room in
                if let name = room.name
                {
                    Button(action: {
                        inviteRoom = room
                    }) {
                        Text(name)
                    }
                    .disabled(room.joinedMembers.contains(user.userId))
                }
            }
        } label:
        {
            Label("Invite to follow me", systemImage: SystemImages.personLineDottedPersonFill.rawValue)
        }
    }
    
    @ViewBuilder
    private var groupsMenu: some View {
        Menu {
            let rooms = Array(session.groups.rooms.values)
            ForEach(rooms) { group in
                if group.iCanInvite,
                   let name = group.name
                {
                    Button(action: {
                        inviteRoom = group
                    }) {
                        Text(name)
                    }
                    .disabled(group.joinedMembers.contains(user.userId))
                }
            }
        } label: {
            Label("Invite to join a group", systemImage: "person.3.fill")
        }
    }
    
    @ViewBuilder
    private var photosMenu: some View {
        Menu {
            let rooms = Array(session.galleries.rooms.values)
            ForEach(rooms) { gallery in
                if gallery.iCanInvite,
                   let name = gallery.name
                {
                    Button(action: {
                        inviteRoom = gallery
                    }) {
                        Text(name)
                    }
                    .disabled(gallery.joinedMembers.contains(user.userId))
                }
            }
        } label: {
            Label("Share a photo gallery", systemImage: "photo.on.rectangle")
        }
    }
    
    @ViewBuilder
    private var invitationSection: some View {
        Section("Invitations") {
            
            circlesMenu
            
            groupsMenu
            
            photosMenu
        }
        .sheet(item: $inviteRoom) { ir in
            RoomInviteOneUserSheet(room: ir, user: user)
        }
    }

    @ViewBuilder
    private var securitySection: some View {
        Section("Security") {
            ForEach(user.devices) { device in
                NavigationLink(destination: DeviceDetailsView(session: room.session, device: device)) {
                    DeviceInfoView(session: room.session, device: device)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var setIgnoreButton: some View {
        let buttonColor: Color = isUserIgnored ? .blue : .red
        let buttonImage = isUserIgnored ? "speaker.fill" : "speaker.slash.fill"
        let confirmationMessage = isUserIgnored ? "Confirm unignoring" : "Confirm ignoring"
        let ignoreMessage = isUserIgnored ? "Unignore" : "Ignore"
        
        Button(action: {
            showConfirmIgnore = true
        }) {
            Label {
                Text("\(ignoreMessage) this user everywhere")
                    .foregroundColor(buttonColor)
            } icon: {
                Image(systemName: buttonImage)
                    .foregroundColor(buttonColor)
            }
        }
        .disabled(userIsMe)
        .confirmationDialog(confirmationMessage,
                            isPresented: $showConfirmIgnore,
                            actions: {
            AsyncButton(role: .none, action: {
                isUserIgnored ? try await room.session.unignoreUser(userId: user.userId) : try await room.session.ignoreUser(userId: user.userId)
                isUserIgnored = user.session.ignoredUserIds.contains(user.userId)
            }) {
                Text("\(ignoreMessage) \(user.displayName ?? user.userId.stringValue)")
            }
        })
    }
    
    var body: some View {
        VStack {
            Form {
                Section("General") {
                    Text("Name")
                        .badge(user.displayName ?? "")
                    
                    if let avatar = user.avatar {
                        HStack {
                            Text("Photo")
                            Spacer()
                            BasicImage(uiImage: avatar, aspectRatio: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    
                    Text("User ID")
                        .badge(user.userId.stringValue)
                }
                
                let power = room.getPowerLevel(userId: user.userId)
                let myPowerLevel = room.myPowerLevel
                
                if power <= myPowerLevel {
                    if room.iCanChangeState(type: M_ROOM_POWER_LEVELS) {
                        powerLevelSection
                    }
                    
                    if !userIsMe {
                        moderationSection
                    }
                }
                
                if !userIsMe {
                    invitationSection
                }
                
                if DebugModel.shared.debugMode {
                    securitySection
                }
            }
        }
        .navigationTitle(user.displayName ?? user.userId.username)
    }
}

