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
    
    @State var thumbnailSize = CGFloat(80)
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
    
    @ViewBuilder
    var body: some View {
        // Get all the top-level messages (ie not the replies etc)
        let messages = room.timeline.values.filter { (message) in
            //message.relatedEventId == nil && message.replyToEventId == nil

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
            
            //let numCols = Int(geometry.size.width) / Int(thumbnailSize+hSpacing)
            let thumbnailSize = geometry.size.width / CGFloat(numCols) - hSpacing
            
            let columns = Array<GridItem>(repeating: GridItem(.fixed(thumbnailSize), spacing: vSpacing), count: numCols)
            
            ScrollView {
                
                LazyVGrid(columns: columns, spacing: hSpacing) {
                    ForEach(messages) { msg in
                        PhotoThumbnailCard(message: msg, height: thumbnailSize, width: thumbnailSize)
                    }
                }
            }
            .onAppear {
                print("GalleryGridView: Found \(messages.count) image/video messages")
            }
            
            footer
        }
        .gesture(MagnificationGesture()
            .onChanged { value in
                print("MAGNIFICATION value = \(value)")
                
                let scale = 1.0 / value
                
                
                let scaled = Int(round(scale * CGFloat(numCols)))

                let newNumCols: Int
                if scale < 1.0 {
                    // If we just apply the new scaling directly, *wow* does the view change super fast when we're shrinking
                    // Let's try averaging betweeen the old value and the raw scaled value
                    newNumCols = (numCols+scaled) / 2
                } else {
                    newNumCols = scaled
                }

                if minCols <= newNumCols && newNumCols <= maxCols {
                    numCols = newNumCols
                }
            }
        )
        .onAppear {
            // Hack kludge to make this @$%*# thing *&#$%ing update
            Task {
                try await Task.sleep(for: .milliseconds(500))
                await MainActor.run {
                    room.objectWillChange.send()
                }
            }
        }
    }
}

/*
struct GalleryGridView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryGridView()
    }
}
*/
