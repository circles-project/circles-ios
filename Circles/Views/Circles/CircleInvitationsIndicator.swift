//
//  CircleInvitationsIndicator.swift
//  Circles
//
//  Created by Charles Wright on 7/19/23.
//

import SwiftUI
import Matrix

struct CircleInvitationsIndicator: View {
    //@Binding var invitations: [Matrix.InvitedRoom]
    @ObservedObject var session: Matrix.Session
    var container: ContainerRoom<CircleSpace>
    
    var body: some View {
        VStack {
            let circleInvitations = session.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }
            if circleInvitations.count > 0 {
                NavigationLink(destination: CircleInvitationsView(session: session, container: container)) {
                    Text("You have \(circleInvitations.count) pending invitation(s)")
                }
            }
        }
    }
}

/*
struct CircleInvitationsIndicator_Previews: PreviewProvider {
    static var previews: some View {
        CircleInvitationsIndicator()
    }
}
*/
