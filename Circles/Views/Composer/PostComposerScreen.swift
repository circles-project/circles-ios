//
//  PostComposerSheet.swift
//  Circles
//
//  Created by Charles Wright on 7/6/21.
//

import SwiftUI
import Matrix

/*
struct PostComposerScreen: View {
    var room: Matrix.Room
    var parentMessage: Matrix.Message?
    var editingMessage: Matrix.Message?
    @State var isPresented = true
    @State var title: String
    
    init(room: Matrix.Room, parentMessage: Matrix.Message? = nil, editingMessage: Matrix.Message? = nil, isPresented: Bool = true) {
        self.room = room
        self.parentMessage = parentMessage
        self.editingMessage = editingMessage
        self.isPresented = isPresented
        
        switch (parentMessage,editingMessage) {
        case (.none, .none):
            self.title = "New Post"
        case (.none, .some):
            self.title = "Edit Post"
        case (.some, .none):
            self.title = "New Reply"
        case (.some, .some):
            self.title = "Edit Reply"
        }
    }
    

    var body: some View {
        VStack {
            ScrollView {
                if let parent = parentMessage {
                    MessageCard(message: parent, isThreaded: true)
                        .padding(3)
                        .padding(.bottom, 5)
                }
                PostComposer(room: room, parent: parentMessage, editing: editingMessage)
                    .padding(3)
                    .padding(.leading, 10)
            }
        }
        .navigationTitle(self.title)
    }
}
 */

/*
struct MessageComposerSheet_Previews: PreviewProvider {
    static var previews: some View {
        MessageComposerSheet()
    }
}
*/
