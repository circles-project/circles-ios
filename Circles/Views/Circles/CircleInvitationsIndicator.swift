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
    @ObservedObject var container: ContainerRoom<Matrix.Room>
    
    var body: some View {
        VStack {
            let invitations = session.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }
            
            if invitations.count > 0 {

                NavigationLink(destination: CircleInvitationsView(session: session, container: container)) {
                    HStack {
                        Spacer()
                        Label("You have \(invitations.count) pending invitation(s)", systemImage: "star")
                            .fontWeight(.bold)
                            .padding()
                        Spacer()
                        Image(systemName: SystemImages.chevronRight.rawValue)
                            .font(.system(size: 24))
                            .padding()
                    }
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .frame(maxHeight: 60)
                }

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
struct CircleInvitationsIndicator_Previews: PreviewProvider {
    static var previews: some View {
        CircleInvitationsIndicator()
    }
}
*/
