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
    @ObservedObject var galleries: ContainerRoom<GalleryRoom>
    //@Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentation
    var parent: Matrix.Message?

    
    //var onCancel: () -> Void
    @State private var newMessageType: String = M_TEXT
    @State private var newMessageText = ""
    @State private var newImage: UIImage?
    @State private var showPicker = false
    @State private var showNewPicker = false
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
    @State var selectedItem: PhotosPickerItem?
    
    /*
    init(room: MatrixRoom, onCancel: @escaping () -> Void) {
        self.room = room
        self.onCancel = onCancel
    }
    */
    
    var buttonBar: some View {
        HStack(spacing: 2.0) {
            Button(action: {
                self.newMessageType = M_TEXT
                self.newImage = nil
            }) {
                Image(systemName: "doc.plaintext")
            }
            .disabled(newMessageType == M_TEXT)
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
                    self.newMessageType = M_IMAGE
                    self.showNewPicker = true
                }) {
                    Label("Upload a photo", systemImage: "photo.fill")
                }
                Button(action: {
                    self.newMessageType = M_IMAGE
                    self.imageSourceType = .local(.camera)
                    self.showPicker = true
                }) {
                    Label("Take a new photo", systemImage: "camera.fill")
                }
                Button(action: {
                    self.newMessageType = M_IMAGE
                    self.imageSourceType = .cloud
                    self.showPicker = true
                }) {
                    Label("Choose an already uploaded photo", systemImage: "photo")
                }
            }
            label: {
                Image(systemName: "photo.fill")
            }
            .disabled(newMessageType == M_IMAGE)

            Spacer()
            Button(role: .destructive, action: {
                //self.isPresented = false
                self.presentation.wrappedValue.dismiss()
                self.newMessageText = ""
                self.newImage = UIImage()
            }) {
                //Image(systemName: "xmark")
                //Text("Cancel")
                Label("Cancel", systemImage: "xmark")
                    //.foregroundColor(.red)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
                    //.background(RoundedRectangle(cornerRadius: 4).stroke(Color.red, lineWidth: 1))
            }
            .buttonStyle(.bordered)
            .padding()

            AsyncButton(action: {
                switch(self.newMessageType) {
                    
                case M_TEXT:
                    if let parentMessage = self.parent {
                        print("REPLY\tSending threaded reply")
                        let replyEventId = try await parentMessage.room.sendReply(to: parentMessage.event, text: self.newMessageText, threaded: true)
                        print("REPLY\tSent eventId = \(replyEventId)")
                        self.presentation.wrappedValue.dismiss()
                    } else {
                        let eventId = try await self.room.sendText(text: self.newMessageText)
                        print("COMPOSER\tSent eventId = \(eventId)")
                        self.presentation.wrappedValue.dismiss()
                    }
                    
                case M_IMAGE:
                    guard let img = self.newImage else {
                        print("COMPOSER Trying to post an image without actually selecting an image")
                        return
                    }
                    
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let eventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true)
                    print("COMPOSER\tSent eventId = \(eventId)")
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
            .buttonStyle(.bordered)
            .padding()

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
                .padding()

            ZStack {
                switch(newMessageType) {
                case M_TEXT:
                    TextEditor(text: $newMessageText)
                        //.frame(height: 90)
                        //.foregroundColor(.gray)
                        .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                        .lineLimit(10)
                case M_IMAGE:
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
            .onChange(of: selectedItem) { newItem in
                print("Selected item changed")
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data)
                    {
                        await MainActor.run {
                            self.newImage = img
                        }
                    } else {
                        // We didn't get a new image
                        if self.newImage == nil {
                            await MainActor.run {
                                self.newMessageType = M_TEXT
                            }
                        }
                    }
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
                .foregroundColor(.background)
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
                CloudImagePicker(galleries: galleries, selectedImage: self.$newImage)
                //Text("FIXME: CloudImagePicker")
            }
        })
        .photosPicker(isPresented: $showNewPicker, selection: $selectedItem, matching: .images)
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
