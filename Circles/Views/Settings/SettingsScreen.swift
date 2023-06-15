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
    
    init(store: CirclesStore, session: CirclesSession) {
        self.store = store
        self.session = session
        self.user = session.matrix.getUser(userId: session.matrix.creds.userId)
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Label("Public Profile", systemImage: "person.crop.circle.fill")) {
                    MessageAuthorHeader(user: user)
                    Text("Status Message")
                    Text("Neopass")
                }
                Section(header: Label("Account Security", systemImage: "lock.fill")) {
                    Text("Password")
                    Text("Email")
                    Text("Login Sessions")
                }
                Section(header: Text("Subscription")) {
                    Text("Expiration Date")
                        .badge("Tomorrow")
                    Text("Cloud Storage")
                        .badge(Text("10GB"))
                }
                Section(header: Text("Other Stuff")) {
                    Text("Notifications")
                    Text("Version")
                        .badge("1.0.0")
                }
                Section(header: Label("Danger Zone", systemImage: "exclamationmark.triangle")) {

                    NavigationLink(destination: LogoutView(user: user)) {
                        Text("Log Out")
                    }
                    
                    Text("Deactivate Account")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
