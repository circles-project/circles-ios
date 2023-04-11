//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  TimelineView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/20/20.
//

import SwiftUI
import Matrix

struct TimelineView: View {
    @ObservedObject var room: Matrix.Room
    var displayStyle: MessageDisplayStyle = .timeline
    @State var debug = false
    @State var loading = false
    @State var selectedMessage: Matrix.Message?
    @State var sheetType: TimelineSheetType?

    /*
    init(room: MatrixRoom, displayStyle: MessageDisplayStyle = .timeline) {
        self.room = room
        self.displayStyle = displayStyle
        //self.messages = room.getMessages(since: Date() - 3*day)
    }
    */
    
    var footer: some View {
        VStack(alignment: .center) {
           
            HStack(alignment: .bottom) {
                Spacer()
                if loading {
                    ProgressView("Loading...")
                        .progressViewStyle(LinearProgressViewStyle())
                }
                else if room.canPaginate() {
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
            
            if CIRCLES_DEBUG {
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
    
    var body: some View {
        // Get all the top-level messages (ie not the replies etc)
        let messages = room.timeline.values.filter { (message) in
            message.relatesToId == nil
        }.sorted(by: {$0.timestamp > $1.timestamp})

        ScrollView {
            LazyVStack(alignment: .center) {

                //let messages = room.messages.sorted(by: {$0.timestamp > $1.timestamp})
                

                    if let msg = room.localEchoMessage {
                        MessageCard(message: msg, displayStyle: displayStyle)
                            .border(Color.red)
                            .padding([.top, .leading, .trailing], 3)
                    }
                    
                    ForEach(messages) { msg in
                        VStack(alignment: .leading) {
                            HStack {
                                /*
                                if CIRCLES_DEBUG && self.debug {
                                    Text("\(messages.firstIndex(of: msg) ?? -1)")
                                }
                                */
                                MessageCard(message: msg, displayStyle: displayStyle)
                                    .padding(.top, 5)
                                    /*
                                    .onAppear {
                                        //print("INFINITE_SCROLL\tChecking to see if we need to paginate")
                                        if msg == messages.last {
                                            print("INFINITE_SCROLL\tPaginating room \(room.displayName ?? "Unnamed room") [\(room.id)]")
                                            loading = true
                                            room.paginate() { _ in
                                                loading = false
                                            }
                                        }
                                    }
                                    */
                            }
                            RepliesView(room: room, parent: msg)
                        }
                    }
                    .padding([.leading, .trailing], 3)


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
