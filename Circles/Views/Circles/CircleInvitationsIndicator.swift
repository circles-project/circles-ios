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
    @EnvironmentObject var matrix: Matrix.Session
    @ObservedObject var container: ContainerRoom<CircleSpace>
    
    var body: some View {
        VStack {
            let circleInvitations = matrix.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }
            if circleInvitations.count > 0 {
                NavigationLink(destination: CircleInvitationsView(container: container)) {
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
