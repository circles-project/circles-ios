//
//  FollowingView.swift
//  Circles
//
//  Created by Charles Wright on 4/18/24.
//

import SwiftUI
import Matrix

struct FollowingView: View {
    @ObservedObject var profile: ProfileSpace
    @Binding var following: [Matrix.User]
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(following) { user in
                    NavigationLink(destination: UnconnectedPersonDetailView(user: user, myProfileRoom: profile)) {
                        PersonHeaderRow(user: user, profile: profile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .padding()
        .navigationTitle("Following")
    }
}
