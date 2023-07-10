//
//  IgnoredUsersView.swift
//  Circles
//
//  Created by Charles Wright on 7/10/23.
//

import SwiftUI
import Matrix

struct IgnoredUsersView: View {
    var session: Matrix.Session
    
    var body: some View {
        VStack {
            ScrollView {
                let ignored = session.ignoredUserIds
                if ignored.isEmpty {
                    Text("Not ignoring any users")
                        .padding()
                } else {
                    ForEach(ignored) { userId in
                        let user = session.getUser(userId: userId)
                        MessageAuthorHeader(user: user)
                            .contextMenu {
                                AsyncButton(action: {
                                    try await user.session.unignoreUser(userId: user.userId)
                                }) {
                                    Label("Un-ignore user", systemImage: "person.wave.2.fill")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(Text("Ignored Users"))
    }
}

/*
struct IgnoredUsersView_Previews: PreviewProvider {
    static var previews: some View {
        IgnoredUsersView()
    }
}
*/
