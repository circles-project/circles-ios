//
//  GroupInvitationsView.swift
//  Circles
//
//  Created by Charles Wright on 8/9/23.
//

import SwiftUI
import Matrix

struct GroupInvitationsView: View {
    //@Binding var invitations: [Matrix.InvitedRoom]
    @ObservedObject var session: Matrix.Session
    var container: ContainerRoom<GroupRoom>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let invitations = session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
                if invitations.isEmpty {
                    Text("No pending invitations")
                } else {
                    ForEach(invitations) { room in
                        let user = room.session.getUser(userId: room.sender)
                        InvitedGroupCard(room: room, user: user, container: container)
                        Divider()
                    }
                }
            }
        }
        .navigationTitle(Text("Group Invitations"))
    }
}

/*
struct GroupInvitationsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupInvitationsView()
    }
}
*/
