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
    @AppStorage("debugMode") var debugMode: Bool = false
    @State var expanded = false
    @State var showReplyComposer = false

    var body: some View {
        VStack(alignment: .leading) {
            let messages = parent.replies ?? []
            
            if messages.isEmpty {
                if debugMode {
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
        .frame(maxWidth: 800)
    }
}

/*
struct RepliesView_Previews: PreviewProvider {
    static var previews: some View {
        RepliesView()
    }
}
*/
