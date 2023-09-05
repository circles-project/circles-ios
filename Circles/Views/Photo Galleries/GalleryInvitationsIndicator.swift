//  Copyright 2023 FUTO Holdings Inc
//
//  GalleryInvitationsIndicator.swift
//  Circles
//
//  Created by Michael Hollister on 9/5/23.
//

import SwiftUI
import Matrix

struct GalleryInvitationsIndicator: View {
    //@Binding var invitations: [Matrix.InvitedRoom]
    @ObservedObject var session: Matrix.Session
    var container: ContainerRoom<GalleryRoom>
    
    var body: some View {
        VStack(alignment: .leading) {
            let invitations = session.invitations.values.filter { $0.type == ROOM_TYPE_PHOTOS }
            
            if !invitations.isEmpty {
                Text("INVITATIONS")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                NavigationLink(destination: GalleryInvitationsView(session: session, container: container)) {
                    Label("\(invitations.count) invitation(s) to shared photo galleries", systemImage: "envelope.open.fill")
                }

                .padding()
            }
        }
    }
}

/*
struct GalleryInvitationsIndicator_Previews: PreviewProvider {
    static var previews: some View {
        GalleryInvitationsIndicator()
    }
}
*/
