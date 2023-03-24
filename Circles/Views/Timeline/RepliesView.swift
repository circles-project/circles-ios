//
//  RepliesView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/21.
//

import SwiftUI
import Matrix

struct RepliesView: View {
    @ObservedObject var room: Matrix.Room
    var parent: Matrix.Message
    @State var expanded = false
    @State var showReplyComposer = false

    var body: some View {
        VStack(alignment: .leading) {
            let messages = parent.replies
            if !expanded && !messages.isEmpty {
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
            }
            if expanded {
                ForEach(messages) { message in
                    MessageCard(message: message, displayStyle: .timeline)
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
