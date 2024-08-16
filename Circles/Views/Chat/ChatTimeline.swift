//
//  ChatTimeline.swift
//  Circles
//
//  Created by Charles Wright on 8/13/24.
//

import SwiftUI
import Matrix

struct ChatTimeline: View {
    @ObservedObject var room: Matrix.ChatRoom
    var threadId: EventId? = nil
    @State var debug = true
    @State var loading = false
    @State var selectedMessage: Matrix.Message?
            
    @ViewBuilder
    var debugInfo: some View {
        VStack {
            if DebugModel.shared.debugMode {
                VStack(alignment: .leading) {
                    if self.debug {
                        Text("Room has \(room.timeline.count) total messages")
                            .font(.caption)
                        Button(action: {self.debug = false}) {
                            Label("Hide debug info", systemImage: SystemImages.eyeSlash.rawValue)
                        }
                        .font(.caption)
                    }
                    else {
                        Button(action: {self.debug = true}) {
                            Label("Show debug info", systemImage: SystemImages.eye.rawValue)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var body: some View {
        // Get all the top-level messages (ie not the replies etc)
        let now = Date()
        let cutoff = now.addingTimeInterval(300.0)
        let allBursts = room.bursts[threadId ?? ""] ?? []
        let session = room.session
        let bursts = allBursts.filter { !session.ignoredUserIds.contains($0.sender.userId) }

        ScrollView {
            LazyVStack(alignment: .center, spacing: 16) {
                
                /*
                if DebugModel.shared.debugMode {
                    Text("threadId = \(threadId ?? "nil")")
                }
                */

                // If this is a chat timeline for a thread,
                // we show the parent message by itself at the top
                if let parentEventId = threadId,
                   let parentMessage = room.timeline[parentEventId],
                   let parentBurst = Matrix.MessageBurst(messages: [parentMessage])
                {
                    ChatMessageBurstView(burst: parentBurst, threaded: true)
                    Divider()
                }
                
                RoomAutoPaginator(room: room)
                
                VStack(alignment: .center, spacing: 0) {
                    ForEach(bursts) { burst in
                        ChatMessageBurstView(burst: burst)
                    }
                }
                
                if let msg = room.localEchoMessage,
                   let burst = Matrix.MessageBurst(messages: [msg])
                {
                    ChatMessageBurstView(burst: burst)
                }
                
                //Spacer()
                
                HStack {
                    Text("Footer")
                }
            }
            .frame(minWidth: 0, maxWidth: TIMELINE_FRAME_MAXWIDTH, minHeight:0, alignment: Alignment.bottom)
            .padding(.horizontal, 12)
        }
        .padding(0)
        .background(Color.greyCool200)
        .refreshable {
            print("REFRESH\tGetting latest messages for room \(room.name ?? room.roomId.stringValue)")
            if let moreMessages: RoomMessagesResponseBody = try? await room.getMessages(forward: false) {
                print("REFRESH\tGot \(moreMessages.chunk.count) more messages from server")
            }
            
            print("REFRESH\tUpdating room state")
            room.updateAvatarImage()
            
            print("REFRESH\tSleeping to let network requests come in")
            try? await Task.sleep(for: .seconds(1))
            
            print("REFRESH\tUpdating un-decrypted messages")
            var count = 0
            for message in room.timeline.values {
                if message.type == M_ROOM_ENCRYPTED {
                    do {
                        try await message.decrypt()
                        count += 1
                    } catch {
                        print("Failed to decrypt message \(message.eventId) in room \(room.roomId)")
                    }
                }
            }
            print("REFRESH\tDecrypted \(count) messages in room \(room.roomId)")
            
            print("REFRESH\tSending Combine update")
            await MainActor.run {
                room.objectWillChange.send()
            }
        }
    }
}

