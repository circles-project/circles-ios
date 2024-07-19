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
    @State var newMessageText = ""
    
    func send() async throws -> EventId {
        let eventId = try await room.sendText(text: newMessageText, inReplyTo: parent)
        await MainActor.run {
            self.newMessageText = ""
        }
        return eventId
    }
    
    @ViewBuilder
    var attachmentButton: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: {
                // Pick media to attach
            }) {
                Text("\(Image(systemName: SystemImages.paperclip.rawValue))")
                    .font(
                        Font.custom("SF Pro Display", size: 18)
                            .weight(.bold)
                    )
                    .multilineTextAlignment(.center)
            }
            .disabled(true)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.top, 9)
        .padding(.bottom, 6)
    }
    
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
                Text("No replies")
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
            
            HStack(spacing: 0) {
                
                attachmentButton
                
                TextField(text: $newMessageText) {
                    Text("Comment")
                }
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit {
                    Task {
                        try await send()
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                AsyncButton(action: {
                    try await send()
                }) {
                    Text("\(Image(systemName: SystemImages.paperplaneFill.rawValue))")
                    .font(
                        Font.custom("SF Pro Display", size: 18)
                            .weight(.bold)
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 40, alignment: .center)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .overlay(
                Rectangle()
                    .inset(by: 0.5)
                    .stroke(Color.greyCool300, lineWidth: 1)
            )
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
