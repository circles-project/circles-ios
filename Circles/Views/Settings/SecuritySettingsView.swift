//
//  SecuritySettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/5/23.
//

import SwiftUI
import Matrix

struct SecuritySettingsView: View {
    var session: Matrix.Session
    
    var body: some View {
        //NavigationView {
        VStack {
            Form {
                NavigationLink {
                    Text("Password")
                }
                label: {
                    Label("Change Password", systemImage: "entry.lever.keypad")
                }
                Label("Login Sessions", systemImage: "iphone")
                Label("Change Email Address", systemImage: "envelope")
            }
            .navigationTitle("Account Security")
        }
    }
}

/*
struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySettingsView()
    }
}
*/
