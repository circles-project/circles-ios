//
//  CircleInvitationsView.swift
//  Circles
//
//  Created by Charles Wright on 7/19/23.
//

import SwiftUI
import Matrix

struct CircleInvitationsView: View {
    @Binding var invitations: [Matrix.InvitedRoom]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(invitations) { room in
                    let user = room.session.getUser(userId: room.sender)
                    InvitedCircleCard(room: room, user: user)
                    Divider()
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
