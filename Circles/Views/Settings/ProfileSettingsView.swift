//
//  ProfileSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/5/23.
//

import SwiftUI
import Matrix

struct ProfileSettingsView: View {
    @ObservedObject var session: Matrix.Session
    //@ObservedObject var user: Matrix.User
    
    var body: some View {
        VStack {
            VStack {
                ProfileImageView(user: session.me)
                    .clipShape(Circle())
                Text("\(session.displayName ?? session.creds.userId.stringValue)")
            }
            Form {
                Text("Profile picture")
                
                NavigationLink(destination: UpdateDisplaynameView(session: session)) {
                    Text("Your name")
                        .badge(session.displayName ?? "(none)")
                }
                
                NavigationLink(destination: UpdateStatusMessageView(session: session)) {
                    Text("Status message")
                        .badge(session.statusMessage ?? "(none)")
                }
            }
        }
        .navigationTitle("Public Profile")
    }
}

/*
struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
    }
}
*/
