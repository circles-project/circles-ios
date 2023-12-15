//
//  RoomMembersSection.swift
//  Circles
//
//  Created by Charles Wright on 11/7/23.
//

import SwiftUI
import Matrix

struct RoomMembersSection: View {
    var title: String
    var users: [UserId]
    var room: Matrix.Room
    
    var body: some View {
        Section(title) {
            ForEach(users) { userId in
                let user = room.session.getUser(userId: userId)
                NavigationLink(destination: GroupMemberDetailView(user: user, room: room)) {
                    RoomMemberRow(user: user, room: room)
                }
            }
        }
    }
}
