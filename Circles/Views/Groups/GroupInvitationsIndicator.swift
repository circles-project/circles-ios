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
    var container: ContainerRoom<GroupRoom>
    
    @State var invitations: [Matrix.InvitedRoom] = []
    
    var body: some View {
        VStack {
            if invitations.count > 0 {
                NavigationLink(destination: GroupInvitationsView(session: session, container: container)) {
                    Text("You have \(invitations.count) pending invitation(s)")
                }
                .padding()
            }
        }
        .onAppear {
            invitations = session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
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
