//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomMessageComposer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/4/20.
//

import SwiftUI
import PhotosUI
import Matrix

struct RoomMessageComposer: View {
    @ObservedObject var room: Matrix.Room
    //@Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentation
    var inReplyTo: Matrix.Message?

    
    //var onCancel: () -> Void
    @State private var newMessageType: Matrix.MessageType = .text
    @State private var newMessageText = ""
    @State private var newImage: UIImage?
    @State private var showPicker = false
    //@State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var inProgress = false
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false

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

            AsyncButton(action: {
                switch(self.newMessageType) {
                    
                case .text:
                    if let parentMessage = self.inReplyTo {
                        print("REPLY\tSending reply")
                        try await parentMessage.room.sendReply(to: parentMessage.eventId, text: self.newMessageText)
                        self.presentation.wrappedValue.dismiss()
                    } else {
                        try await self.room.sendText(text: self.newMessageText)
                        self.presentation.wrappedValue.dismiss()
                    }
                    
                case .image:
                    guard let img = self.newImage else {
                        print("COMPOSER Trying to post an image without actually selecting an image")
                        return
                    }
                    
                    try await self.room.sendImage(image: img)
                    self.presentation.wrappedValue.dismiss()
                    
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
            let myUserId = room.session.creds.userId
            let myUser = room.session.getUser(userId: myUserId)
            MessageAuthorHeader(user: myUser)

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
                default:
                    ImagePicker(selectedImage: $newImage, sourceType: localSourceType)
                }
            case .cloud:
                //CloudImagePicker(session: room.session, selectedImage: self.$newImage)
                Text("FIXME: CloudImagePicker")
            }
        })
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
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
