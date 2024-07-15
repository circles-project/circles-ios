//
//  PeopleInvitationsView.swift
//  Circles
//
//  Created by Charles Wright on 8/1/23.
//

import SwiftUI
import Matrix

struct PeopleInvitationsView: View {
    @ObservedObject var session: Matrix.Session
    @ObservedObject var people: ContainerRoom<Matrix.SpaceRoom>
    
    var body: some View {
        ScrollView {
            VStack {
                let invites = session.invitations.values.filter { $0.type == M_SPACE }
                ForEach(invites) { invite in
                    let user = session.getUser(userId: invite.sender)

                    HStack(alignment: .top) {
                        UserAvatarView(user: user)
                            .frame(width: 120, height: 120)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(invite.name ?? user.displayName ?? "??")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("From:")
                                Text(invite.sender.stringValue)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Spacer()
                                AsyncButton(role: .destructive, action: {
                                    try await invite.reject()
                                }) {
                                    Label("Reject", systemImage: "hand.thumbsdown.fill")
                                        .padding(5)
                                }
                                Spacer()
                                AsyncButton(action: {
                                    let roomId = invite.roomId
                                    try await invite.accept()
                                    try await people.addChild(roomId)
                                }) {
                                    Label("Accept", systemImage: "hand.thumbsup.fill")
                                        .padding(5)
                                }
                                Spacer()
                            }
                        }
                        .padding(.leading)
                    }
                    
                    Divider()
                }
            }
            .padding()
        }
        .navigationTitle(Text("Invitations to Connect"))
    }
}

/*
struct PeopleInvitationsView_Previews: PreviewProvider {
    static var previews: some View {
        PeopleInvitationsView()
    }
}
*/
