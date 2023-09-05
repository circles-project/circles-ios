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
    @EnvironmentObject var matrix: Matrix.Session
    @ObservedObject var container: ContainerRoom<GroupRoom>
    
    var body: some View {
        VStack {
            let circleInvitations = matrix.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
            if circleInvitations.count > 0 {
                NavigationLink(destination: GroupInvitationsView(container: container)) {
                    Text("You have \(circleInvitations.count) pending invitation(s)")
                }
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
