//
//  SettingsScreen.swift
//  Circles
//
//  Created by Charles Wright on 4/12/23.
//

import Foundation
import SwiftUI

import Matrix

struct SettingsScreen: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var session: CirclesApplicationSession
    var user: Matrix.User
    
    @AppStorage("developerMode") var developerMode: Bool = false
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @AppStorage("showCirclesHelpText") var showCirclesHelpText = true
    @AppStorage("showGroupsHelpText") var showGroupsHelpText = true
    
    @State var showConfirmLogout = false
    @State var showConfirmSwitch = false
    
    init(store: CirclesStore, session: CirclesApplicationSession) {
        self.store = store
        self.session = session
        self.user = session.matrix.getUser(userId: session.matrix.creds.userId)
    }
    
    
    var body: some View {
        NavigationStack {
            Form {

                Section("General") {
                    NavigationLink(destination: ProfileSettingsView(session: session.matrix)) {
                        Label("Public Profile", systemImage: "person.circle.fill")
                    }
                    
                    NavigationLink(destination: SecuritySettingsView(session: session.matrix)) {
                        Label("Account Security", systemImage: "lock.fill")
                    }
                    
                    NavigationLink(destination: NotificationsSettingsView(store: store)) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: IgnoredUsersView(session: session.matrix)) {
                        Label("Ignored Users", systemImage: "person.2.slash.fill")
                    }
                }
                
                Section("About") {
                    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "???"
                    Label("Version", systemImage: "123.rectangle.fill")
                        .badge(version)
                        .onTapGesture(count: 7){
                            print("Setting developerMode = true")
                            developerMode = true
                        }
                    
                    NavigationLink(destination: AcknowledgementsView()) {
                        Label("Acknowledgements", systemImage: "hands.clap.fill")
                    }
                }

                
                if developerMode {
                    Section("Developer Mode") {
                        Toggle(isOn: $developerMode) {
                            Label("Developer Mode", systemImage: "wrench.and.screwdriver.fill")
                        }
                        
                        Toggle(isOn: $debugMode) {
                            Label("Debug Mode", systemImage: "ladybug.fill")
                        }
                        
                        Toggle(isOn: $showCirclesHelpText) {
                            Text("Circles tab \"help\" popup")
                        }
                        
                        Toggle(isOn: $showGroupsHelpText) {
                            Text("Groups tab \"help\" popup")
                        }
                    }
                }
                
                /*
                Section(header: Text("Subscription")) {
                    Text("Expiration Date")
                        .badge("Tomorrow")
                    Text("Cloud Storage")
                        .badge(Text("10GB"))
                }
                */
                
                Section(header: Label("Danger Zone", systemImage: "exclamationmark.triangle")) {
                    
                    Button(action: {
                        self.showConfirmSwitch = true
                    }) {
                        Label("Switch User", systemImage: "person.2.fill")
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Confirm Switch User",
                                        isPresented: $showConfirmSwitch,
                                        actions: {
                                            AsyncButton(action: {
                                                try await store.softLogout()
                                            }) {
                                                Label("Take me back to login", systemImage: "person.2.fill")
                                            }
                                        },
                                        message: {
                                            Text("This will return you to the login screen without losing the ability to receive encrypted posts.  But be careful: Anyone can log back in to this account without entering the password.")
                                        }
                    )
                    
                    Button(action: { showConfirmLogout = true }) {
                        Label("Log Out", systemImage: "power")
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Confirm Log Out",
                                        isPresented: $showConfirmLogout,
                                        actions: {
                                            AsyncButton(role: .destructive, action: { try await store.logout() }) {
                                                Text("Log me out")
                                            }
                                        },
                                        message: {
                                            Text("WARNING: You must be logged in on at least one device in order to receive decryption keys from your friends. If you log out from all devices, you may be unable to decrypt any posts or comments sent while you are logged out.")
                                        }
                    )
                    
                    NavigationLink(destination: DeactivateAccountView(store: store, session: session)) {
                        Label("Deactivate Account", systemImage: "person.fill.xmark")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
