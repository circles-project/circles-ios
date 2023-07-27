//
//  ThreadView.swift
//  Circles
//
//  Created by Charles Wright on 7/27/23.
//

import SwiftUI
import Matrix

struct ThreadView<V: MessageView>: View {
    @ObservedObject var room: Matrix.Room
    var root: Matrix.Message
    var messages: [Matrix.Message]
    
    init(room: Matrix.Room, root: Matrix.Message) {
        self.room = room
        self.root = root
        // We need an ordered collection to use a ForEach in the View, so sort the Set into an Array
        if let thread: Set<Matrix.Message> = room.threads[root.eventId] {
            self.messages = thread.sorted(by: {$0.timestamp > $1.timestamp} )
        } else {
            self.messages = [root]
        }
    }
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages) { message in
                    V(message: message, isLocalEcho: false, isThreaded: true)
                }
            }
        }
        .navigationTitle(Text("Thread"))
    }
}

/*
struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadView()
    }
}
*/
