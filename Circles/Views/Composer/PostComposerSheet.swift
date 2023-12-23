//
//  PostComposerSheet.swift
//  Circles
//
//  Created by Charles Wright on 7/6/21.
//

import SwiftUI
import Matrix

struct PostComposerSheet: View {
    var room: Matrix.Room
    var parentMessage: Matrix.Message?
    var editingMessage: Matrix.Message?
    @State var isPresented = true

    var body: some View {
        VStack {
            Text("New Post")
                .font(.title2)
                .fontWeight(.bold)
                .padding(5)
            
            ScrollView {
                if let parent = parentMessage {
                    MessageCard(message: parent)
                        .padding(3)
                        .padding(.bottom, 5)
                }
                PostComposer(room: room, parent: parentMessage, editing: editingMessage)
                    .padding(3)
                    .padding(.leading, 10)
            }
        }
    }
}

/*
struct MessageComposerSheet_Previews: PreviewProvider {
    static var previews: some View {
        MessageComposerSheet()
    }
}
*/
