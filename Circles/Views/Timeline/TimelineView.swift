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
    @AppStorage("debugMode") var debugMode: Bool = false
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
                } else if debugMode {
                    Text("Not currently loading; Can't paginate")
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .frame(minHeight: TIMELINE_BOTTOM_PADDING)
            
            if debugMode {
                VStack(alignment: .leading) {
                    if self.debug {
                        Text("Room has \(room.timeline.count) total messages")
                            .font(.caption)
                        Button(action: {self.debug = false}) {
                            Label("Hide debug info", systemImage: "eye.slash")
                        }
                        .font(.caption)
                    }
                    else {
                        Button(action: {self.debug = true}) {
                            Label("Show debug info", systemImage: "eye")
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
            message.relatedEventId == nil && message.replyToEventId == nil && message.timestamp < cutoff
        }.sorted(by: {$0.timestamp > $1.timestamp})

        ScrollView {
            LazyVStack(alignment: .center, spacing: 5) {

                //let messages = room.messages.sorted(by: {$0.timestamp > $1.timestamp})
                

                    if let msg = room.localEchoMessage {
                        V(message: msg, isLocalEcho: true, isThreaded: false)
                            .border(Color.red)
                            .padding([.top, .leading, .trailing], 3)
                            .frame(maxWidth: TIMELINE_FRAME_MAXWIDTH)
                    }
                    
                    ForEach(messages) { message in
                        if message.type == M_ROOM_MESSAGE ||
                            message.type == M_ROOM_ENCRYPTED ||
                            message.type == ORG_MATRIX_MSC3381_POLL_START {
                            
                            VStack(alignment: .leading) {
                                
                                V(message: message, isLocalEcho: false, isThreaded: false)
                                    .padding(.top, 5)

                                RepliesView(room: room, parent: message)
                                
                            }
                            .onAppear {
                                message.loadReactions()
                            }
                        } else if debugMode && message.stateKey != nil {
                            StateEventView(message: message)
                        }
                    }
                    .padding([.leading, .trailing], 3)
                    .frame(maxWidth: TIMELINE_FRAME_MAXWIDTH)


                    Spacer()
                
                footer
                
            }
        }
        .refreshable {
            print("REFRESH\tGetting latest messages for room \(room.name ?? room.roomId.stringValue)")
            if let msgs = try? await room.getMessages(forward: false) {
                print("REFRESH\tGot response from server")
            }
            
            print("REFRESH\tUpdating room state")
            room.updateAvatarImage()
            
            print("REFRESH\tSleeping to let network requests come in")
            try? await Task.sleep(for: .seconds(1))
            
            print("REFRESH\tSending Combine update")
            await MainActor.run {
                room.objectWillChange.send()
            }
            print("REFRESH\tDone")
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
