//
//  FriendsOfFriendsView.swift
//  Circles
//
//  Created by Charles Wright on 4/18/24.
//

import SwiftUI
import Matrix

struct FriendsOfFriendsView: View {
    @ObservedObject var profile: ProfileSpace
    @ObservedObject var people: ContainerRoom<Matrix.SpaceRoom>
    @Binding var friendsOfFriends: [UserId]?
    
    var body: some View {
        ScrollView {
            if let userIds = friendsOfFriends {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(userIds, id: \.self) { userId in
                        if userId != profile.session.creds.userId {
                            let user = profile.session.getUser(userId: userId)

                            NavigationLink(destination: PersonDetailView(user: user, myProfileRoom: profile)) {
                                PersonHeaderRow(user: user, profile: profile)
                                    //.contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .padding()
        .navigationTitle("Friends of Friends")
    }
}
