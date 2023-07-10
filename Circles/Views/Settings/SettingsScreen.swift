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
    @ObservedObject var session: CirclesSession
    var user: Matrix.User
    
    @AppStorage("developerMode") var developerMode: Bool = false
    @AppStorage("debugMode") var debugMode: Bool = false
    
    init(store: CirclesStore, session: CirclesSession) {
        self.store = store
        self.session = session
        self.user = session.matrix.getUser(userId: session.matrix.creds.userId)
    }
    
    
    var body: some View {
        NavigationStack {
            Form {

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
                
                let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "???"
                Label("Version", systemImage: "123.rectangle.fill")
                    .badge(version)
                    .onTapGesture(count: 7){
                        print("Setting developerMode = true")
                        developerMode = true
                    }
                
                if developerMode {
                    Section("Developer Mode") {
                        Toggle("Developer Mode", isOn: $developerMode)
                        
                        Toggle("Debug Mode", isOn: $debugMode)
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

                    NavigationLink(destination: LogoutView(store: store)) {
                        Label("Log Out", systemImage: "power")
                    }
                    
                    NavigationLink(destination: DeactivateAccountView(store: store)) {
                        Label("Deactivate Account", systemImage: "person.fill.xmark")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
