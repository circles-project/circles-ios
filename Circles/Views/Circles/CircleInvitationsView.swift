//
//  CircleInvitationsView.swift
//  Circles
//
//  Created by Charles Wright on 7/19/23.
//

import SwiftUI
import Matrix

struct CircleInvitationsView: View {
    //@Binding var invitations: [Matrix.InvitedRoom]
    @EnvironmentObject var matrix: Matrix.Session
    @ObservedObject var container: ContainerRoom<CircleSpace>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let invitations = matrix.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }
                if invitations.isEmpty {
                    Text("No pending invitations")
                } else {
                    ForEach(invitations) { room in
                        let user = matrix.getUser(userId: room.sender)
                        InvitedCircleCard(room: room, user: user, container: container)
                        Divider()
                    }
                }
            }
        }
        .navigationTitle(Text("Circle Invitations"))
    }
}

/*
struct CircleInvitationsView_Previews: PreviewProvider {
    static var previews: some View {
        CircleInvitationsView()
    }
}
*/
