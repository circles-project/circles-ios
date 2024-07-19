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
    @State var newMessageText = ""
    
    func send() async throws -> EventId {
        let eventId = try await room.sendText(text: newMessageText, inReplyTo: parent)
        await MainActor.run {
            self.newMessageText = ""
        }
        return eventId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            
            if messages.isEmpty && DebugModel.shared.debugMode {
                Text("No replies")
            }
            

            ScrollView {
                ForEach(messages) { message in
                    MessageCard(message: message, isThreaded: true)
                }
            }

            Divider()
            
            HStack(spacing: 4) {
                Button(action: {
                    // Pick media to attach
                }) {
                    Image(systemName: SystemImages.paperclipCircleFill.rawValue)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .disabled(true)
                
                TextField(text: $newMessageText) {
                    Text("Message")
                }
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit {
                    Task {
                        try await send()
                    }
                }
                
                AsyncButton(action: {
                    try await send()
                }) {
                    Image(systemName: SystemImages.paperplaneCircleFill.rawValue)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding(4)
            
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
