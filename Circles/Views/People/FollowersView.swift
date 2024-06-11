//
//  FollowersView.swift
//  Circles
//
//  Created by Charles Wright on 4/18/24.
//

import SwiftUI
import Matrix

struct FollowersView: View {
    @ObservedObject var profile: ProfileSpace
    @Binding var followers: [Matrix.User]
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(followers) { user in
                    NavigationLink(destination: PersonDetailView(user: user, myProfileRoom: profile)) {
                        PersonHeaderRow(user: user, profile: profile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .padding()
        .navigationTitle("My Followers")
    }
}
