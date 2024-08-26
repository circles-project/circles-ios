//
//  ChatInvitationsView.swift
//  Circles
//
//  Created by Charles Wright on 8/13/24.
//

import SwiftUI
import Matrix

struct ChatInvitationsView: View {
    @ObservedObject var session: Matrix.Session
    @ObservedObject var container: ContainerRoom<Matrix.ChatRoom>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                let invitations = session.invitations.values.filter { $0.type == nil }
                if invitations.isEmpty {
                    Text("No pending invitations")
                } else {
                    ForEach(invitations) { room in
                        let user = room.session.getUser(userId: room.sender)
                        InvitedChatCard(room: room, user: user, container: container)
                            .frame(maxWidth: 350)

                        Divider()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(Text("Chat Invitations"))
    }
}
