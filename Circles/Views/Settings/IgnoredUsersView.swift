//
//  IgnoredUsersView.swift
//  Circles
//
//  Created by Charles Wright on 7/10/23.
//

import SwiftUI
import Matrix

struct IgnoredUsersView: View {
    @ObservedObject var session: Matrix.Session
    
    var body: some View {
        Form {
            Section("Ignored Users") {
                let ignored = session.ignoredUserIds
                if ignored.isEmpty {
                    Text("Not ignoring any users")
                        .padding()
                } else {
                    ForEach(ignored) { userId in
                        let user = session.getUser(userId: userId)
                        
                        HStack {
                            UserAvatarView(user: user)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .frame(width: 60, height: 60)
                            VStack(alignment: .leading) {
                                UserNameView(user: user)
                                Text(user.userId.stringValue)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            AsyncButton(action: {
                                try await user.session.unignoreUser(userId: user.userId)
                            }) {
                                Image(systemName: SystemImages.trash.rawValue)
                                    .foregroundColor(.red)
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
