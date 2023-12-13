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
                        .progressViewStyle(LinearProgressViewStyle())
                }
                else if room.canPaginate {
                    AsyncButton(action: {
                        self.loading = true
                        try await room.paginate()
                        self.loading = false
                    }) {
                        Text("Load More")
                    }
                    .onAppear {
                        // It's a magic self-clicking button.
                        // If it ever appears, we basically automatically click it for the user
                        self.loading = true
                        let _ = Task {
                            try await room.paginate()
                            self.loading = false
                        }
                    }
                }
                Spacer()
            }
            
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
        let messages = room.timeline.values.filter { (message) in
            message.relatedEventId == nil && message.replyToEventId == nil
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

    }
}

/*
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}
*/
