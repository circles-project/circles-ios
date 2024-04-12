//
//  SingleTimelineView.swift
//  Circles
//
//  Created by Charles Wright on 4/12/24.
//

import SwiftUI
import Matrix

struct SingleTimelineView: View {
    @ObservedObject var room: Matrix.Room
    
    var body: some View {
        let user = room.session.getUser(userId: room.creator)
        let title = "\(user.displayName ?? user.userId.stringValue): \(room.name ?? "Timeline")"
        TimelineView<MessageCard>(room: room)
            .navigationTitle(title)
    }
}


