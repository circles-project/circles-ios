//  Copyright 2023 FUTO Holdings Inc
//
//  PhotosUploadView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/23.
//

import SwiftUI
import PhotosUI
import Matrix

struct PhotosUploadView: View {
    typealias UploadTask = Task<Void,Error>
        
    var room: Matrix.Room
    @State var task: UploadTask?
    @Binding var items: [PhotosPickerItem]
    @Binding var total: Int
    @State var currentItem: PhotosPickerItem?
    @State var currentImage: UIImage?
    @State var canceled = false
    
    var body: some View {
        VStack(alignment: .center) {
            if canceled {
                Text("Upload canceled")
            }
            else if items.isEmpty && currentItem != nil {
                Text("Done!")
                    .font(.headline)
                    .fontWeight(.bold)
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80, alignment: .center)
            } else {
                if let image = currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
                let ratio = Float(total-items.count) / Float(total)
                ProgressView(value: ratio) {
                    Text("Uploading \(total-items.count) of \(total)...")
                }
                .padding(10)
                Button(role: .destructive, action: {
                    if let t = task {
                        t.cancel()
                    }
                    self.task = nil
                    self.total = 0
                    self.currentItem = nil
                    self.currentImage = nil
                    self.canceled = true
                    self.items.removeAll()
                }) {
                    Text("Cancel")
                }
                .padding(10)
            }
        }
        .padding(10)
        .onAppear {
            task = task ?? UploadTask(priority: .background) {
                
                CirclesApp.logger.debug("Uploading \(items.count) items")

                while !items.isEmpty {
                    currentItem = items.removeFirst()
                    
                    guard let item = currentItem
                    else { break }
                    
                    if item.supportedContentTypes.contains(where: {
                        CirclesApp.logger.debug("Checking whether \($0) is a movie type")
                        return $0.isSubtype(of: .movie)
                    }) {
                        // Load it as a movie
                        CirclesApp.logger.debug("Loading movie")
                        if let movie = try? await item.loadTransferable(type: Movie.self) {
                            CirclesApp.logger.debug("Successfully Loaded movie")
                            if !Task.isCancelled {
                                let thumbnail = try await movie.loadThumbnail()
                                await MainActor.run {
                                    self.currentImage = thumbnail
                                }
                                let url = movie.url
                                try await room.sendVideo(url: url, thumbnail: thumbnail)
                            }
                        } else {
                            // FIXME: Set error message
                            CirclesApp.logger.error("Failed to load movie")
                        }
                    }
                    else if item.supportedContentTypes.contains(where: {
                        CirclesApp.logger.debug("Checking whether \($0) is an image type")
                        return $0.isSubtype(of: .image)
                    }),
                            let data = try? await currentItem?.loadTransferable(type: Data.self),
                            let img = UIImage(data: data)
                    {
                        CirclesApp.logger.debug("Loading image")
                        await MainActor.run {
                            self.currentImage = img
                        }
                        try await room.sendImage(image: img, withBlurhash: false)
                    }
                    else {
                        CirclesApp.logger.debug("Unknown content types: \(item.supportedContentTypes)")
                    }
                }
                currentItem = nil
                task = nil
                total = 0
            }
        }
    }
}

/*
struct PhotosUploadView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosUploadView()
    }
}
*/
