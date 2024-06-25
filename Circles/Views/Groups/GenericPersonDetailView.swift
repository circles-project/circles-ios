//
//  GenericPersonDetailView.swift
//  Circles
//
//  Created by Charles Wright on 12/14/23.
//

import SwiftUI
import Matrix

struct GenericPersonDetailView: View {
    @ObservedObject var user: Matrix.User
    
    var header: some View {
        HStack {
            UserAvatarView(user: user)
                .frame(width: 160, height: 160, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                //.padding(.leading)
            VStack(alignment: .leading) {
                Text(user.displayName ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                Text(user.id)
                    .font(.subheadline)
            }
        }
    }
    
    var body: some View {
        VStack {
            ScrollView {
                
                header
                
                //status
                
                Divider()
                

                Button(action: {}) {
                    Label("Invite to connect", systemImage: SystemImages.link.rawValue)
                        .padding()
                }
                
                Button(action: {}) {
                    Label("Invite to follow me", systemImage: SystemImages.personLineDottedPersonFill.rawValue)
                        .padding()
                }
                
                Button(role: .destructive, action: {}) {
                    Label("Ignore this user", systemImage: SystemImages.personFillXmark.rawValue)
                        .padding()
                }
                
            }
        }
        .padding()
        .onAppear {
            // Hit the Homeserver to make sure we have the latest
            //user.matrix.getDisplayName(userId: user.id) { _ in }
                user.refreshProfile()
        }
        .navigationTitle(user.displayName ?? user.userId.username)
    }
}
