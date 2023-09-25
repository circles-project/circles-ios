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
    
    @State var invitations: [Matrix.InvitedRoom] = []
    
    var body: some View {
        VStack {
            if invitations.count > 0 {
                NavigationLink(destination: CircleInvitationsView(session: session, container: container)) {
                    Text("You have \(invitations.count) pending invitation(s)")
                }
            }
        }
        .onAppear {
            invitations = session.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }
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
