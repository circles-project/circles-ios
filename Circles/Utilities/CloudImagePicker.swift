//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CloudImagePicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/12/21.
//

import SwiftUI
import Matrix

struct GalleryThumbnail: View {
    @ObservedObject var message: Matrix.Message
    
    var body: some View {
        ZStack {
            Image(uiImage: message.thumbnail ?? message.blur ?? UIImage())
        }
        .onAppear {
            if message.thumbnail == nil && (message.content?.thumbnail_url != nil || message.content?.thumbnail_file != nil) {
                let _ = Task {
                    try await message.fetchThumbnail()
                }
            }
        }
    }
}

struct GalleryPicker: View {
    @ObservedObject var room: Matrix.Room
    var completion: (UIImage) -> Void = { _ in }
    
    var body: some View {
        let messages = room.timeline.values.filter {
            $0.type == M_ROOM_MESSAGE && $0.content?.msgtype == .image
        }

        
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {

                
                ForEach(messages) { message in
                    AsyncButton(action: {
                        // Download the image
                        guard let content = message.content as? Matrix.mImageContent
                        else {
                            // FIXME: Set error message
                            return
                        }
                        
                        if let file = content.file {
                            guard let data = try? await message.room.session.downloadAndDecryptData(file),
                                  let img = UIImage(data: data)
                            else {
                                // FIXME: Set error message
                                return
                            }
                            completion(img)
                            return
                        }

                        if let mxc = content.url {
                            guard let data = try? await message.room.session.downloadData(mxc: mxc),
                                  let img = UIImage(data: data)
                            else {
                                // FIXME: Set error message
                                return
                            }
                            completion(img)
                            return
                        }
                        
                        // Looks like we failed to get the image :(
                        // FIXME: Set error message
                        return
                    }) {
                        GalleryThumbnail(message: message)
                    }
                }
            }
        }
    }
}

struct CloudImagePicker: View {
    @EnvironmentObject var galleries: ContainerRoom<GalleryRoom>
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentation
    
    @State var selectedRoom: Matrix.Room? = nil
    var completion: (UIImage) -> Void = { _ in }
    
    var topbar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(.subheadline)
            }
            
            Spacer()
            
        }
    }
    
    var roomList: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(galleries.rooms) { room in
                    Button(action: {
                        self.selectedRoom = room
                    }) {
                        PhotoGalleryCard(room: room)
                    }
                }
            }
        }
    }
    
    
    
    var body: some View {
        VStack {
            topbar
            
            Divider()
            
            if let room = self.selectedRoom {

                HStack {
                    Text(room.name ?? "(Untitled gallery)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        self.selectedRoom = nil
                    }) {
                        Text("Back")
                    }
                }
                
                GalleryPicker(room: room, completion: { image in
                    self.completion(image)
                    self.presentation.wrappedValue.dismiss()
                })
                
            }
            else {
            
                HStack(alignment: .bottom) {
                    Text("My Galleries")
                        .font(.title2)
                        .fontWeight(.bold)
                
                    Spacer()
                
                    Button(action: {
                        // FIXME: Implement this?
                    }) {
                        Text("See All")
                    }
                }
            
                roomList
            }

        }
        .padding()
        
    }
}

/*
struct CloudImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        CloudImagePicker()
    }
}
*/
