//
//  ChatThreadView.swift
//  Circles
//
//  Created by Charles Wright on 8/15/24.
//

import SwiftUI
import Matrix

struct ChatThreadView: View {
    @ObservedObject var room: Matrix.ChatRoom
    @ObservedObject var parent: Matrix.Message
    
    var body: some View {
        ChatTimeline(room: room, threadId: parent.eventId)
            .navigationTitle(Text("Thread"))
    }
}


