//  Copyright 2023 FUTO Holdings Inc
//
//  GalleryGridView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/23.
//

import SwiftUI
import Matrix

struct GalleryGridView: View {
    @ObservedObject var room: GalleryRoom
    @State var debug = false
    @State var loading = false
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @State var prevZoom: Double = 1.0
    
    @State var numCols = 4
    let maxCols = 16
    let minCols = 1
    
    let supportedMessageTypes = [M_IMAGE, M_VIDEO]
    
    
    
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
    
    private func handleMagnification(zoom: MagnificationGesture.Value) {
        withAnimation(.easeIn(duration: 0.1)) {
            
            // FIXME: Look instead at the change between `zoom` and the previous value
            let ratio = zoom / prevZoom
            
            let epsilon = 0.10
            if ratio > 1.0+epsilon && numCols > minCols {
                numCols -= 1
            }
            
            if ratio < 1.0-epsilon && numCols < maxCols {
                numCols += 1
            }
            
            prevZoom = zoom
        }
    }
    
    @ViewBuilder
    var body: some View {
        // Get all the top-level messages (ie not the replies etc)
        let messages = room.timeline.values.filter { (message) in
            //message.relatedEventId == nil && message.replyToEventId == nil

            // Allow events that fail decryption to be displayed to the user
            if message.type == M_ROOM_ENCRYPTED {
                return true
            }
            
            guard message.relatedEventId == nil,
                  message.replyToEventId == nil,
                  message.type == M_ROOM_MESSAGE,
                  let content = message.content as? Matrix.MessageContent,
                  supportedMessageTypes.contains(content.msgtype)
            else {
                return false
            }
            return true

        }.sorted(by: {$0.timestamp > $1.timestamp})
        
        GeometryReader { geometry in
            
            //let thumbnailSize = geometry.size.width > 300 ? CGFloat(240) : CGFloat(96)
            //let hSpacing = geometry.size.width > 800 ? 8.0 : 4.0
            let hSpacing = CGFloat(4)
            let vSpacing = hSpacing
            
            let thumbnailSize = geometry.size.width / CGFloat(numCols) - hSpacing
            
            let columns = Array<GridItem>(repeating: GridItem(.fixed(thumbnailSize), spacing: vSpacing), count: numCols)
            
            ScrollView {
                
                LazyVGrid(columns: columns, spacing: hSpacing) {
                    ForEach(messages) { message in
                        // To handle event replacement (aka edits) we need to find the latest version of the message
                        // * If there's a replacement, use that one
                        // * Otherwise use the original one
                        let currentMessage = message.replacement ?? message
                        PhotoThumbnailCard(message: currentMessage, height: thumbnailSize, width: thumbnailSize)
                    }
                }
            }
            .onAppear {
                print("GalleryGridView: Found \(messages.count) image/video messages")
            }

        }
        .gesture(MagnificationGesture()
            .onChanged(handleMagnification)
            .onEnded(handleMagnification)
        )
        
    }
}

/*
struct GalleryGridView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryGridView()
    }
}
*/
