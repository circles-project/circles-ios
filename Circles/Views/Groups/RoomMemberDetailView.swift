//
//  GroupMemberDetailView.swift
//  Circles
//
//  Created by Charles Wright on 12/14/23.
//

import SwiftUI
import Matrix

struct RoomMemberDetailView: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var room: Matrix.Room
    
    @State private var selectedPower: Int
    
    @State private var showConfirmChangeSelf = false
    @State private var newSelfPowerLevel: Int?
    
    @State private var showConfirmIgnore = false
    @State private var showConfirmKick = false
    @State private var showConfirmBan = false
    
    private var userIsMe: Bool
    
    let roles = [
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
        
        print("My power = \(room.myPowerLevel) vs theirs = \(selectedPower)")
    }
    
    @ViewBuilder
    var powerLevelSection: some View {
        let myPowerLevel = room.myPowerLevel
        
        Section("Power level") {
        
            Picker("Role", selection: $selectedPower) {
                let availableRoles = roles.filter { key,value in
                    key <= myPowerLevel
                }
                ForEach(availableRoles, id: \.key) { key,value in
                    Text(value)
                }
            }
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
                Label("WARNING: You are about to change your own power level.  This cannot be undone.", systemImage: "exclamationmark.triangle")
            } )
            
        }
    }
    
    @ViewBuilder
    var moderationSection: some View {
        Section("Moderation") {
            
            Button(role: .destructive, action: {
                showConfirmIgnore = true
            }) {
                Label {
                    Text("Ignore user everywhere")
                } icon: {
                    Image(systemName: "speaker.slash.fill")
                        .foregroundColor(.red)
                }
            }
            .disabled(userIsMe)
            .confirmationDialog("Confirm ignoring",
                                isPresented: $showConfirmIgnore,
                                actions: {
                AsyncButton(role: .destructive, action: {
                    try await room.session.ignoreUser(userId: user.userId)
                }) {
                    Text("Ignore \(user.displayName ?? user.userId.stringValue)")
                }
            })
            
            if room.iCanKick {
                Button(role: .destructive, action: {
                    showConfirmKick = true
                }) {
                    if let name = room.name {
                        Label {
                            Text("Remove user from \(name)")
                        } icon: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                            
                    } else {
                        Label {
                            Text("Remove user")
                        } icon: {
                            Image(systemName: "minus.circle.fill")
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
                            Text("Ban user from \(name)")
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                            
                    } else {
                        Label {
                            Text("Ban user")
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
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
    var invitationSection: some View {
        Section("Invitations") {
            Button(action: {}) {
                Label("Invite user to connect", systemImage: "link")
            }
            
            Button(action: {}) {
                Label("Invite user to follow me", systemImage: "person.line.dotted.person.fill")
            }
            
            Button(action: {}) {
                Label("Invite user to join a group", systemImage: "person.3.fill")
            }
            
            Button(action: {}) {
                Label("Share a photo gallery", systemImage: "photo.on.rectangle")
            }
        }
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
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFit()
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
                    powerLevelSection
                    
                    moderationSection
                }
                
                if !userIsMe {
                    invitationSection
                }
            }
        }
        .navigationTitle(user.displayName ?? user.userId.username)
    }
}

