//
//  RepliesView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/21.
//

import SwiftUI

struct RepliesView: View {
    @ObservedObject var room: MatrixRoom
    var parent: MatrixMessage
    @State var expanded = false
    @State var showReplyComposer = false

    var body: some View {
        VStack(alignment: .leading) {
            let messages = room.getReplies(to: parent.id)
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
