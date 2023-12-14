//
//  RoomKnockIndicator.swift
//  Circles
//
//  Created by Charles Wright on 10/10/23.
//

import SwiftUI
import Matrix

struct RoomKnockIndicator: View {
    @ObservedObject var room: Matrix.Room
    
    var body: some View {
        if room.iCanInvite {
            HStack {
                Spacer()
                NavigationLink(destination: RoomKnockDetailsView(room: room)) {
                    Label("Review \(room.knockingMembers.count) request(s) for invitations", systemImage: "star.fill")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
            }
            .background(Color.accentColor)
            .frame(maxHeight: 60)
        }
    }
}
