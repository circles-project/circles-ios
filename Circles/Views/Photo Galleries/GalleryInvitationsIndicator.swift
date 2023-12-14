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
    
                NavigationLink(destination: GalleryInvitationsView(session: session, container: container)) {
                    HStack {
                        Spacer()
                        Label("\(invitations.count) invitation(s) to shared galleries", systemImage: "star")
                            .fontWeight(.bold)
                            .padding()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24))
                            .padding()
                    }
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .frame(maxHeight: 80)
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
