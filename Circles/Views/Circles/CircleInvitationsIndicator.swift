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
    @ObservedObject var container: ContainerRoom<CircleSpace>
    
    @State var invitations: [Matrix.InvitedRoom] = []
    
    var body: some View {
        HStack {
            Spacer()
            NavigationLink(destination: CircleInvitationsView(session: session, container: container)) {
                Text("You have \(invitations.count) pending invitation(s)")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
            }
            Spacer()
        }
        .background(Color.accentColor)
        .frame(maxHeight: 60)
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
