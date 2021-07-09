//
//  MessageComposerSheet.swift
//  Circles
//
//  Created by Charles Wright on 7/6/21.
//

import SwiftUI

struct MessageComposerSheet: View {
    var room: MatrixRoom
    @Binding var parentMessage: MatrixMessage?
    @State var isPresented = true

    var body: some View {
        VStack {
            Text("New Post")
                .font(.title2)
                .fontWeight(.bold)
            
            if let parent = parentMessage {
                MessageCard(message: parent, displayStyle: .timeline)
            }
            RoomMessageComposer(room: room, inReplyTo: parentMessage)
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
