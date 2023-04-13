//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//  Copyright 2023 FUTO Holdings Inc
//
//  CircleTimeline.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/6/20.
//

import SwiftUI
import Matrix

struct CircleTimeline: View {
    @ObservedObject var space: CircleSpace
    private var formatter: DateFormatter
    @State private var showDebug = false
    @State private var loading = false

    init(space: CircleSpace) {
        self.space = space
        self.formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
    }
    
    var debugFooter: some View {
        VStack(alignment: .leading) {
            Button(action: {self.showDebug = false}) {
                Label("Hide debug info", systemImage: "eye.slash")
            }
            Text("\(space.rooms.count) rooms in the Stream")
            ForEach(space.rooms) { room in
                let owner = room.creator
                let messages = room.messages
                    
                HStack {
                    Text("\(messages.count) total messages in \(owner.description): \(room.name ?? room.roomId.description)")
                        .padding(.leading, 10)
                    if owner == room.session.creds.userId {
                        Text("(my room)")
                            .fontWeight(.bold)
                    }
                }
                if let firstMessage = messages.first,
                   let ts = firstMessage.timestamp {
                    Text("since \(formatter.string(from: ts))")
                        .padding(.leading, 20)
                }
            }
            /*
            let lfr = stream.lastFirstRoom
            Text("Last first room is \(lfr?.displayName ?? "None")")
            */
        }
        .font(.caption)
    }
    
    var body: some View {
        //let messages = stream.getTopLevelMessages()
        // FIXME: Hacky kludgy version
        let messages = space.rooms.reduce([], { (messages, room) -> [Matrix.Message] in
            messages + room.messages
        })
        VStack(alignment: .leading) {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(messages) { msg in
                        VStack(alignment: .leading) {
                            HStack {
                                let index: Int = messages.firstIndex(of: msg)!
                                if CIRCLES_DEBUG && showDebug {
                                    Text("\(index)")
                                }
                                MessageCard(message: msg)
                            }
                            RepliesView(room: msg.room, parent: msg)
                        }
                    }
                    .padding([.top, .leading, .trailing], 3)
                }
            
                HStack(alignment: .bottom) {
                    Spacer()
                    if loading {
                        ProgressView("Loading...")
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    else if space.canPaginate {
                        AsyncButton(action: {
                            try await space.paginate()
                        }) {
                            Text("Load More")
                        }
                        .onAppear {
                            // Basically it's like we automatically click "Load More" for the user
                            let _ = Task {
                                try await space.paginate()
                            }
                        }
                    }
                    
                    Spacer()
                }
            }



            if CIRCLES_DEBUG {
                if showDebug {
                    debugFooter
                } else {
                    Button(action: {self.showDebug = true}) {
                        Label("Show debug info", systemImage: "eye")
                            .font(.footnote)
                    }
                }
            }

        }

    }
}

/*
struct StreamTimeline_Previews: PreviewProvider {
    static var previews: some View {
        StreamScreen()
    }
}
 */
