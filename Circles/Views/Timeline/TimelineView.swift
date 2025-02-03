//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  TimelineView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/20/20.
//

import SwiftUI
import Matrix

struct TimelineView<V: MessageView>: View {
    @ObservedObject var room: Matrix.Room
    @EnvironmentObject var viewModel: TimelineViewModel

    @State var debug = false
    @State var loading = false
    @State var selectedMessage: Matrix.Message?
    
    var footer: some View {
        VStack(alignment: .center) {
            HStack(alignment: .bottom) {
                Spacer()
                if loading {
                    ProgressView("Loading...")
                }
                else if room.canPaginate {
                    AsyncButton(action: {
                        self.loading = true
                        do {
                            try await room.paginate()
                        } catch {
                            print("Paginate failed")
                        }
                        self.loading = false
                    }) {
                        Text("Load More")
                    }
                    .onAppear {
                        // It's a magic self-clicking button.
                        // If it ever appears, we basically automatically click it for the user
                        self.loading = true
                        let _ = Task {
                            do {
                                try await room.paginate()
                            } catch {
                                print("Paginate failed")
                            }
                            self.loading = false
                        }
                    }
                } else if DebugModel.shared.debugMode {
                    Text("Not currently loading; Can't paginate")
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .frame(minHeight: TIMELINE_BOTTOM_PADDING)
            
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
        let messages = room.timeline.values.filter { (message) in
            message.relatedEventId == nil &&
            message.replyToEventId == nil &&
            message.timestamp < cutoff &&
            !message.room.session.ignoredUserIds.contains(message.sender.userId)
        }.sorted(by: {$0.timestamp > $1.timestamp})

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .center, spacing: 10) {
                    
                    if let msg = room.localEchoMessage {
                        MessageCard(message: msg, isLocalEcho: true, isThreaded: false)
                        //.border(Color.red)
                            .frame(maxWidth: TIMELINE_FRAME_MAXWIDTH)
                            .id(msg.eventId)
                    }
                    
                    ForEach(messages) { message in
                        if message.type == M_ROOM_MESSAGE ||
                            message.type == M_ROOM_ENCRYPTED ||
                            message.type == ORG_MATRIX_MSC3381_POLL_START {
                            
                            MessageCard(message: message, isLocalEcho: false, isThreaded: false)
                                .id(message.eventId)
                                .onAppear {
                                    message.loadReactions()
                                }
                        } else if DebugModel.shared.debugMode && message.stateKey != nil {
                            StateEventView(message: message)
                                .id(message.eventId)
                        }
                    }
                    
                    Spacer()
                    
                    footer
                }
                .frame(maxWidth: TIMELINE_FRAME_MAXWIDTH)
                .padding(.horizontal, 12)
                
            }
            .onChange(of: viewModel.scrollPosition) { eventId in
                proxy.scrollTo(eventId)
            }
            .padding(0)
            .background(Color.greyCool200)
            .refreshable {
                print("REFRESH\tGetting latest messages for room \(room.name ?? room.roomId.stringValue)")
                if let moreMessages: RoomMessagesResponseBody = try? await room.getMessages(forward: true) {
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
}

/*
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}
*/
