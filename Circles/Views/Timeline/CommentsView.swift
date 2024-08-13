//
//  CommentsView.swift (previously RepliesView.swift)
//  Circles
//
//  Created by Charles Wright on 6/15/21.
//

import SwiftUI
import Matrix

struct CommentsView: View {
    var room: Matrix.Room
    @ObservedObject var parent: Matrix.Message
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
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
            
            Text("Comments")
                .font(
                    Font.custom("Inter", size: 16)
                        .weight(.bold)
                )
                .multilineTextAlignment(.center)
                .foregroundColor(Color.greyCool1100)
                .frame(minHeight: 45, maxHeight: 45)
                .padding(.top, 8)
            
            Divider()
            
            if messages.isEmpty && DebugModel.shared.debugMode {
                Text("No comments")
            }
            

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(messages) { message in
                        CommentCard(message: message)
                    }
                }
            }
            .padding(16)

            Divider()
            
            SmallComposer(room: room, parent: parent)
        }
    }
}

/*
struct RepliesView_Previews: PreviewProvider {
    static var previews: some View {
        RepliesView()
    }
}
*/
