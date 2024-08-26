//
//  ChatInvitationsIndicator.swift
//  Circles
//
//  Created by Charles Wright on 8/13/24.
//

import SwiftUI
import Matrix

struct ChatInvitationsIndicator: View {
    @ObservedObject var session: Matrix.Session
    @ObservedObject var container: ContainerRoom<Matrix.ChatRoom>
        
    var body: some View {
        VStack {
            let invitations = session.invitations.values.filter { $0.type == nil }
            if invitations.count > 0 {
                HStack {
                    Spacer()
                    NavigationLink(destination: ChatInvitationsView(session: session, container: container)) {
                        Label("You have \(invitations.count) pending invitation(s)", systemImage: "star")
                            .fontWeight(.bold)
                            .padding()
                    }
                    Spacer()
                    Image(systemName: SystemImages.chevronRight.rawValue)
                        .font(.system(size: 24))
                        .padding()
                }
                .foregroundColor(.white)
                .background(Color.accentColor)
                .frame(maxHeight: 60)
            }
            if DebugModel.shared.debugMode {
                Text("Debug: \(invitations.count) invitations here; \(session.invitations.count) total in the session")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}
