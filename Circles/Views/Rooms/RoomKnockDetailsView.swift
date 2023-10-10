//
//  RoomKnockDetailsView.swift
//  Circles
//
//  Created by Charles Wright on 10/10/23.
//

import SwiftUI
import Matrix

struct RoomKnockDetailsView: View {
    @ObservedObject var room: Matrix.Room
    

    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(room.knockingMembers) { userId in
                //ForEach([UserId("@cvwright:circu.li")!]) { userId in
                    Divider()
                    let user = room.session.getUser(userId: userId)
                    KnockingUserCard(user: user, room: room)
                }
            }
        }
    }
}
