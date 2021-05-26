//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  StreamScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/6/20.
//

import SwiftUI

struct StreamTimeline: View {
    @ObservedObject var stream: SocialStream
    private var formatter: DateFormatter
    @State private var showDebug = false
    
    init(stream: SocialStream) {
        self.stream = stream
        self.formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
    }
    
    var debugFooter: some View {
        VStack(alignment: .leading) {
            Button(action: {self.showDebug = false}) {
                Label("Hide debug info", systemImage: "eye.slash")
            }
            Text("\(stream.rooms.count) rooms in the Stream")
            ForEach(stream.rooms) { room in
                let owners = room.owners.compactMap { user in
                        user.displayName
                    }
                    .joined(separator: ", ")
                    
                HStack {
                    Text("\(room.messages.count) total messages in \(owners): \(room.displayName ?? room.id)")
                        .padding(.leading, 10)
                    if room.tags.contains(ROOM_TAG_OUTBOUND) {
                        Text("(writable)")
                            .fontWeight(.bold)
                    }
                }
                if let firstMessage = room.first,
                   let ts = firstMessage.timestamp {
                    Text("since \(formatter.string(from: ts))")
                        .padding(.leading, 20)
                }
            }
            let lfr = stream.lastFirstRoom
            Text("Last first room is \(lfr?.displayName ?? "None")")
        }
        .font(.caption)
    }
    
    var body: some View {
        let messages = stream.getMessages()
        VStack(alignment: .leading) {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(messages) { msg in
                        let index: Int = messages.firstIndex(of: msg)!
                        HStack {
                            if KOMBUCHA_DEBUG && showDebug {
                                Text("\(index)")
                            }
                            MessageCard(message: msg, displayStyle: .timeline)
                        }
                    }
                    .padding([.top, .leading, .trailing], 5)
                }
            
                HStack(alignment: .bottom) {
                    Spacer()
                    Button(action: {
                        stream.paginate()
                    }) {
                        Text("Load More")
                    }
                    .disabled(!stream.canPaginate)
                    Spacer()
                }
            }



            if KOMBUCHA_DEBUG {
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
