//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomMessageComposer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/4/20.
//

import SwiftUI
import PhotosUI

struct RoomMessageComposer: View {
    @ObservedObject var room: MatrixRoom
    //@Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentation
    var inReplyTo: MatrixMessage?

    
    //var onCancel: () -> Void
    @State private var newMessageType: MatrixMsgType = .text
    @State private var newMessageText = ""
    @State private var newImage: UIImage?
    @State private var showPicker = false
    //@State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var inProgress = false

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
                self.newImage = nil
            }) {
                Image(systemName: "doc.plaintext")
            }
            .disabled(newMessageType == .text)
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
            .disabled(newMessageType == .image)

            Spacer()
            Button(action: {
                //self.isPresented = false
                self.presentation.wrappedValue.dismiss()
                self.newMessageText = ""
                self.newImage = UIImage()
            }) {
                //Image(systemName: "xmark")
                //Text("Cancel")
                Label("Cancel", systemImage: "xmark")
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
                    //.background(RoundedRectangle(cornerRadius: 4).stroke(Color.red, lineWidth: 1))
            }

            Button(action: {
                switch(self.newMessageType) {
                case .text:
                    self.inProgress = true
                    if let parentMessage = self.inReplyTo {
                        print("REPLY\tSending reply")
                        parentMessage.postReply(text: self.newMessageText) { response in
                            if response.isSuccess {
                                //self.isPresented = false
                                self.presentation.wrappedValue.dismiss()
                            }
                            self.inProgress = false
                        }
                    } else {
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
                                //self.isPresented = false
                                self.presentation.wrappedValue.dismiss()
                            }
                            self.inProgress = false
                        }
                    }
                case .image:
                    guard let img = self.newImage else {
                        print("COMPOSER Trying to post an image without actually selecting an image")
                        return
                    }
                    self.inProgress = true
                    room.postImage(image: img, caption: newMessageText) { response in
                        switch(response) {
                        case .failure(let err):
                            print("COMPOSER Failed to post image: \(err)")
                        case .success(let maybeMsg):
                            print("COMPOSER Successfully posted image.  Got response [\(maybeMsg ?? "(No message)")].")
                            //self.isPresented = false
                            self.presentation.wrappedValue.dismiss()
                        }
                        self.inProgress = false
                    }
                default:
                    print("COMPOSER Doing nothing for now...")
                }
            }) {
                //Image(systemName: "paperplane.fill")
                //Text("Send")
                Label("Send", systemImage: "paperplane.fill")
                    .disabled(inProgress)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
                    //.background(RoundedRectangle(cornerRadius: 4).stroke(Color.blue, lineWidth: 1))
            }

        }
        //.padding([.leading, .trailing])
        .padding(.leading)
    }
    
    var body: some View {
        GeometryReader { proxy in
        VStack(alignment: .leading, spacing: 2) {
            MessageAuthorHeader(user: room.matrix.me())

            ZStack {
                switch(newMessageType) {
                case .text:
                    TextEditor(text: $newMessageText)
                        //.frame(height: 90)
                        //.foregroundColor(.gray)
                        .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                        .lineLimit(10)
                case .image:
                        VStack(alignment: .center, spacing: 2) {
                            Image(uiImage: self.newImage ?? UIImage())
                                //.scaledToFit()
                                .resizable()
                                .scaledToFit()
                                //.frame(height: imageHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                //.layoutPriority(-1)
                            //TextField("Enter your optional caption here", text: $newMessageText)
                            TextEditor(text: $newMessageText)
                                .lineLimit(2)
                                //.frame(height: textHeight)
                                //.foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                                .padding(5)
                                //.layoutPriority(1)
                        }
                default:
                    Image(uiImage: self.newImage ?? UIImage())
                }

                if inProgress {
                    Color.gray
                        .opacity(0.70)

                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: .white)
                        )
                        .scaleEffect(2.5, anchor: .center)
                }
            }

            buttonBar
        }
        .onAppear {
            print("GeometryReader says w = \(proxy.size.width) x h = \(proxy.size.height)")
        }
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
            switch self.imageSourceType {
            case .local(let localSourceType):
                switch localSourceType {
                case .photoLibrary, .savedPhotosAlbum:
                    // Use the new privacy-friendly PHPicker instead
                    //PhotoPicker(isPresented: $showPicker, selectedImage: $newImage)
                    // Actually the new PHPicker sucks
                    // * Can't load WebP
                    // * Can't load the example images that have both heic and jpeg
                    ImagePicker(selectedImage: self.$newImage, sourceType: localSourceType)
                case .camera:
                    ImagePicker(selectedImage: $newImage, sourceType: .camera)
                }
            case .cloud:
                CloudImagePicker(matrix: room.matrix, selectedImage: self.$newImage)
            }
        })
        .onAppear() {
            room.matrix.ensureEncryption(roomId: room.id) { _ in
                // Nothing we can really do here anyway
            }
        }

    }
    
}

/*
struct TimelineMessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        TimelineMessageComposer()
    }
}
 */
