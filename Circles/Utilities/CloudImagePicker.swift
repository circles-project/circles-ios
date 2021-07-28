//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CloudImagePicker.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/12/21.
//

import SwiftUI

struct CloudImagePicker: View {
    var matrix: MatrixInterface
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentation
    
    @State var selectedRoom: MatrixRoom? = nil
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
                ForEach(matrix.getRooms(for: ROOM_TAG_PHOTOS)) { room in
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
                    Text(room.displayName ?? "(Untitled gallery)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        self.selectedRoom = nil
                    }) {
                        Text("Back")
                    }
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(
                            room.messages
                                .filter { msg in
                                    switch(msg.content) {
                                    case .image( _):
                                        return true
                                    default:
                                        return false
                                    }
                                }
                                .sorted(by: { $0.timestamp > $1.timestamp })
                        ) { message in
                            switch(message.content) {
                            case .image(let content):
                                Button(action: {
                                    print("CLOUDPICKER\tUser tapped image [\(message.id)]")
                                    // Get the image
                                    // Set self.selectedImage to it
                                    // Dismiss the sheet?
                                    if let url = content.url {
                                        matrix.downloadImage(mxURI: url.absoluteString) { image in
                                            self.selectedImage = image
                                            self.presentation.wrappedValue.dismiss()
                                        }
                                    } else if let file = content.info.file {
                                        matrix.downloadEncryptedImage(fileinfo: file, mimetype: content.info.mimetype) { response in
                                            switch response {
                                            case .failure:
                                                print("CLOUDPICKER\tFailed to download encrypted image for [\(message.id)]")
                                            case .success(let image):
                                                self.selectedImage = image
                                                self.presentation.wrappedValue.dismiss()
                                            }
                                        }
                                    } else {
                                        print("CLOUDPICKER\tError: no URL or encrypted file for [\(message.id)]")
                                        print("\t\tURL  = \(content.url?.absoluteString ?? "")")
                                        print("\t\tfile = \(content.info.file?.url.absoluteString ?? "")")
                                        print("\t\tthumbnail_file = \(content.info.thumbnail_file?.url.absoluteString ?? "")")
                                    }
                                }) {
                                    VStack(alignment: .center) {
                                        MessageThumbnail(message: message)
                                        MessageTimestamp(message: message)
                                    }
                                }
                                .padding()
                                /*
                                if let img = message.thumbnailImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    
                                }
                                */
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            else {
            
                HStack(alignment: .bottom) {
                    Text("My Albums")
                        .font(.title2)
                        .fontWeight(.bold)
                
                    Spacer()
                
                    Button(action: {}) {
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
