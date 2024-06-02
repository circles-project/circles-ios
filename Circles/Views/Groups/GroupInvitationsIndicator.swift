//
//  GroupInvitationsIndicator.swift
//  Circles
//
//  Created by Charles Wright on 8/9/23.
//

import SwiftUI
import Matrix

struct GroupInvitationsIndicator: View {
    //@Binding var invitations: [Matrix.InvitedRoom]
    @ObservedObject var session: Matrix.Session
    @ObservedObject var container: ContainerRoom<GroupRoom>
        
    var body: some View {
        VStack {
            let invitations = session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
            if invitations.count > 0 {
                HStack {
                    Spacer()
                    NavigationLink(destination: GroupInvitationsView(session: session, container: container)) {
                        Label("You have \(invitations.count) pending invitation(s)", systemImage: "star")
                            .fontWeight(.bold)
                            .padding()
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
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

/*
struct GroupInvitationsIndicator_Previews: PreviewProvider {
    static var previews: some View {
        GroupInvitationsIndicator()
    }
}
*/
