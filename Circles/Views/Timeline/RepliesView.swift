//
//  RepliesView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/21.
//

import SwiftUI
import Matrix

struct RepliesView: View {
    var room: Matrix.Room
    @ObservedObject var parent: Matrix.Message
    @State var expanded = false
    @State var showReplyComposer = false

    var body: some View {
        VStack(alignment: .leading) {
            let now = Date()
            let cutoff = now.addingTimeInterval(300.0)
            let allMessages = parent.replies.values
            let messages = allMessages.filter {
                $0.timestamp < cutoff  &&                                     // Filter out messages claiming to be from the future
                !$0.room.session.ignoredUserIds.contains($0.sender.userId)    // Filter out messages from ignored users
            }
            .sorted {
                $0.timestamp < $1.timestamp
            }
            
            if messages.isEmpty {
                if DebugModel.shared.debugMode {
                    HStack {
                        Spacer()
                        Text("No replies")
                    }
                } else {
                    EmptyView()
                }
            }
            else {
                if !expanded {
                    HStack {
                        Spacer()
                        Button(action: {
                            self.expanded = true
                            room.objectWillChange.send()
                        }) {
                            Text("Show \(messages.count) replies")
                                .font(.footnote)
                        }
                    }
                } else {
                    ForEach(messages) { message in
                        MessageCard(message: message)
                    }
                    HStack {
                        Spacer()
                        Button(action: {
                            self.expanded = false
                            room.objectWillChange.send()
                        }) {
                            Text("Hide replies")
                                .font(.footnote)
                        }
                    }
                }
            }
        }
        .padding(.leading)
    }
}

/*
struct RepliesView_Previews: PreviewProvider {
    static var previews: some View {
        RepliesView()
    }
}
*/
