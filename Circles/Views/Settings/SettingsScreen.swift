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
    
    @AppStorage(DEFAULTS_KEY_ENABLE_GALLERIES, store: .standard) var enableGalleries: Bool = false
    
    @AppStorage("developerMode") var developerMode: Bool = false
    
    @AppStorage("showCirclesHelpText") var showCirclesHelpText = true
    @AppStorage("showGroupsHelpText") var showGroupsHelpText = true
    
    @State var showConfirmLogout = false
    @State var showConfirmSwitch = false
    @State var showChangelog = false
    
    init(store: CirclesStore, session: CirclesApplicationSession) {
        self.store = store
        self.session = session
        self.user = session.matrix.getUser(userId: session.matrix.creds.userId)
    }
    
    
    var body: some View {
        NavigationSplitView {
            Form {
                Section("General") {
                    NavigationLink(destination: ProfileSettingsView(session: session.matrix)) {
                        Label("Public Profile", systemImage: "person.circle.fill")
                    }
                    
                    NavigationLink(destination: SecuritySettingsView(session: session.matrix)) {
                        Label("Account Security", systemImage: SystemImages.lockFill.rawValue)
                    }
                    
                    /*
                    if CIRCLES_DOMAINS.contains(session.matrix.creds.userId.domain) {
                        NavigationLink(destination: SubscriptionSettingsView(store: store.appStore)) {
                            Label("Subscription Status", systemImage: "folder.badge.person.crop")
                        }
                    }
                    */
                    
                    NavigationLink(destination: StorageSettingsView(session: session.matrix)) {
                        Label("Storage", systemImage: "folder.fill")
                    }
                    
                    NavigationLink(destination: NotificationsSettingsView(store: store, matrix: session.matrix)) {
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
                    
                    Label {
                        Link("Circles iOS Privacy Policy", destination: URL(string: PRIVACY_POLICY_URL)!)
                    } icon: {
                        Image(systemName: SystemImages.link.rawValue)
                    }
                    
                    Label {
                        Link("License Agreement", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    } icon: {
                        Image(systemName: SystemImages.link.rawValue)
                    }
                }

                Section("Advanced") {
                    Toggle(isOn: $enableGalleries) {
                        Label("Enable photo galleries", systemImage: "photo.fill")
                    }
                    .tint(.orange)

                    Button("Show list of changes", systemImage: "newspaper.fill") {
                        showChangelog = true
                    }
                }
                
                if developerMode {
                    Section("Developer Mode") {
                        Toggle(isOn: $developerMode) {
                            Label("Developer Mode", systemImage: "wrench.and.screwdriver.fill")
                        }
                        .tint(.orange)

                        
                        Toggle(isOn: DebugModel.shared.$debugMode) {
                            Label("Debug Mode", systemImage: "ladybug.fill")
                        }
                        .tint(.orange)
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
                
                Section(header: Label("Danger Zone", systemImage: SystemImages.exclamationmarkTriangle.rawValue)) {
                    Button(action: {
                        self.showConfirmSwitch = true
                    }) {
                        Label("Switch User", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Confirm Switch User",
                                        isPresented: $showConfirmSwitch,
                                        actions: {
                                            AsyncButton(action: {
                                                try await store.softLogout()
                                            }) {
                                                Text("Take me back to login")
                                            }
                                        },
                                        message: {
                                            Text("This will return you to the login screen without losing the ability to receive encrypted posts.  But be careful: Anyone can log back in to this account without entering the password.")
                                        }
                    )
                    
                    Button(action: { showConfirmLogout = true }) {
                        Label("Log Out", systemImage: "power")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Confirm Log Out",
                                        isPresented: $showConfirmLogout,
                                        actions: {
                                            AsyncButton(role: .destructive, action: {
                                                try await store.logout()
                                            }) {
                                                Text("Log me out")
                                            }
                                        },
                                        message: {
                                            Text("WARNING: You must be logged in on at least one device in order to receive decryption keys from your friends. If you log out from all devices, you may be unable to decrypt any posts or comments sent while you are logged out.")
                                        }
                    )
                    NavigationLink(destination: DeactivateAccountView(store: store, session: session).background(Color.greyCool200)) {
                        Label("Deactivate Account", systemImage: SystemImages.personFillXmark.rawValue)
                    }
                }
            }
            .navigationTitle("Settings")
        } detail: {
            ProfileSettingsView(session: session.matrix)
        }
        .sheet(isPresented: $showChangelog) {
            ChangelogSheet(content: ChangelogFile().loadMarkdown(named: .fullList), title: .fullList, showChangelog: $showChangelog)
        }
    }
}
