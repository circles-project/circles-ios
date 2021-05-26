//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomMessageComposer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/4/20.
//

import SwiftUI

struct RoomMessageComposer: View {
    @ObservedObject var room: MatrixRoom
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    
    //var onCancel: () -> Void
    @State private var newMessageType: MatrixMsgType = .text
    @State private var newMessageText = ""
    @State private var newImage: UIImage?
    @State private var showPicker = false
    //@State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary

    enum ImageSourceType {
        case cloud
        case local(UIImagePickerController.SourceType)
    }
    
    @State private var imageSourceType: ImageSourceType = .local(.photoLibrary)
    
    /*
    init(room: MatrixRoom, onCancel: @escaping () -> Void) {
        self.room = room
        self.onCancel = onCancel
    }
    */
    
    var buttonBar: some View {
        HStack(spacing: 10.0) {
            Button(action: {
                self.newMessageType = .text
            }) {
                Image(systemName: "doc.plaintext")
            }
            /*
            Button(action: {
                self.newMessageType = .image
                self.imageSourceType = .photoLibrary
                self.showPicker = true
            }) {
                Image(systemName: "photo.fill")
            }
            Button(action: {
                self.newMessageType = .image
                self.imageSourceType = .camera
                self.showPicker = true
            }) {
                Image(systemName: "camera.fill")
            }
            */
            Menu {
                Button(action: {
                    self.newMessageType = .image
                    self.imageSourceType = .local(.photoLibrary)
                    self.showPicker = true
                }) {
                    Label("Upload a photo from device library", systemImage: "photo.fill")
                }
                Button(action: {
                    self.newMessageType = .image
                    self.imageSourceType = .local(.camera)
                    self.showPicker = true
                }) {
                    Label("Take a new photo", systemImage: "camera.fill")
                }
                Button(action: {
                    self.newMessageType = .image
                    self.imageSourceType = .cloud
                    self.showPicker = true
                }) {
                    Label("Choose an already uploaded photo", systemImage: "photo")
                }
            }
            label: {
                Image(systemName: "photo.fill")
            }
            Spacer()
            Button(action: {
                self.isPresented = false
                self.newMessageText = ""
                self.newImage = UIImage()
            }) {
                Image(systemName: "xmark")
                Text("Cancel")
            }
            .foregroundColor(.red)
            .padding(.vertical, 2)
            .padding(.horizontal, 5)
            .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red, lineWidth: 1))
            Button(action: {
                switch(self.newMessageType) {
                case .text:
                    self.room.postText(text: self.newMessageText) { response in
                        switch(response) {
                        case .failure(let error):
                            print("COMPOSER Failed to post text message: \(error)")
                            // FIXME Set a Bool to show an Alert
                        case .success(let str):
                            print("COMPOSER Successfully posted text message")
                            if let eventId = str {
                                  print("COMPOSER Got event id \(eventId)")
                            }
                            self.isPresented = false
                        }
                    }
                case .image:
                    guard let img = self.newImage else {
                        print("COMPOSER Trying to post an image without actually selecting an image")
                        return
                    }
                    room.postImage(image: img) { response in
                        switch(response) {
                        case .failure(let err):
                            print("COMPOSER Failed to post image: \(err)")
                        case .success(let maybeMsg):
                            print("COMPOSER Successfully posted image.  Got response [\(maybeMsg ?? "(No message)")].")
                            self.isPresented = false
                        }
                    }
                default:
                    print("COMPOSER Doing nothing for now...")
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                Text("Send")
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 5)
            .background(RoundedRectangle(cornerRadius: 4).stroke(Color.blue, lineWidth: 1))
        }
        //.padding([.leading, .trailing])
        .padding(.leading)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MessageAuthorHeader(user: room.matrix.me())
            
            switch(newMessageType) {
            case .text:
                TextEditor(text: $newMessageText)
                    .frame(height: 90)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                    .lineLimit(10)
            case .image:
                Image(uiImage: self.newImage ?? UIImage())
                    //.frame(height: 150)
                    //.scaledToFit()
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            default:
                Image(uiImage: self.newImage ?? UIImage())
            }

            buttonBar
        }
        .padding(.all, 3.0)
        //.padding([.top, .leading, .trailing], 5)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .shadow(color: .gray, radius: 2, x: 0, y: 1)
        )
        //.border(Color.red, width: 1)
        .sheet(isPresented: $showPicker, content: {
            //Text("Photo Picker")
            switch self.imageSourceType {
            case .local(let localSourceType):
                ImagePicker(selectedImage: self.$newImage, sourceType: localSourceType)
            case .cloud:
                CloudImagePicker(matrix: room.matrix, selectedImage: self.$newImage)
            }
        })

    }
    
}

/*
struct TimelineMessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        TimelineMessageComposer()
    }
}
 */
