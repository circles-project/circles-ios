//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomMessageComposer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/4/20.
//

import SwiftUI
import PhotosUI
import QuickLookThumbnailing
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
    @State private var newMovie: Movie?
    @State private var showPicker = false
    @State private var showNewPicker = false
    @State private var newPickerFilter: PHPickerFilter = .images
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
        HStack(spacing: 5.0) {
            Button(action: {
                self.newMessageType = M_TEXT
                self.newImage = nil
            }) {
                Image(systemName: "doc.plaintext")
                    .scaleEffect(1.5)
            }
            .disabled(newMessageType == M_TEXT)
            .padding(1)

            Menu(content: {
                Button(action: {
                    self.newMessageType = M_IMAGE
                    self.newPickerFilter = .images
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
            },
            label: {
                Image(systemName: "photo.fill")
                    .scaleEffect(1.5)
            })
            .disabled(newMessageType == M_IMAGE)
            .padding(1)

            
            Menu(content: {
                Button(action: {
                    self.newMessageType = M_VIDEO
                    self.newPickerFilter = .videos
                    self.showNewPicker = true
                }) {
                    Label("Upload a video", systemImage: "film")
                }
            },
            label: {
                Image(systemName: "film")
                    .scaleEffect(1.5)
            })
            .disabled(newMessageType == M_VIDEO)
            .padding(1)

            
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
            .padding(3)

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
                        print("COMPOSER\tSent m.text with eventId = \(eventId)")
                        self.presentation.wrappedValue.dismiss()
                    }
                    
                case M_IMAGE:
                    guard let img = self.newImage else {
                        print("COMPOSER Trying to post an image without actually selecting an image")
                        return
                    }
                    
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let eventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true)
                    print("COMPOSER\tSent m.image with eventId = \(eventId)")
                    self.presentation.wrappedValue.dismiss()
                    
                    
                case M_VIDEO:
                    guard let movie = self.newMovie,
                          let thumbnail = movie.thumbnail
                    else {
                        print("COMPOSER Trying to post a video without actually selecting a video")
                        return
                    }
                    
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let eventId = try await self.room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption)
                    print("COMPOSER\tSent m.video with eventId = \(eventId)")
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
            .padding(3)

        }
        //.padding([.leading, .trailing])
        .padding(.leading)
    }
    
    var body: some View {
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
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        TextEditor(text: $newMessageText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(5)
                    }
                case M_VIDEO:
                    VStack(alignment: .center, spacing: 2) {
                        Image(uiImage: self.newMovie?.thumbnail ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        TextEditor(text: $newMessageText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(5)
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
                print("PICKER Selected item changed")
                if let item = newItem {
                    Task {
                        let contentTypes = item.supportedContentTypes
                        for contentType in contentTypes {
                            guard let mimeType = contentType.preferredMIMEType
                            else { continue }
                            print("PICKER Found mimetype \(mimeType)")
                        }
                                                
                        // If we are supposed to be loading an image, load the whole thing right now
                        if self.newMessageType == M_IMAGE {
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
                            return
                        }
                        
                        if self.newMessageType == M_VIDEO {
                            if let movie = try? await newItem?.loadTransferable(type: Movie.self) {
                                print("PICKER User picked a video: \(movie.url.absoluteString)")
                                let thumb = try await movie.loadThumbnail()
                                await MainActor.run {
                                    self.newMovie = movie
                                }
                            } else {
                                print("PICKER Failed to get a new video")
                            }
                        }
                    }
                }
            }

            buttonBar
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
        .photosPicker(isPresented: $showNewPicker, selection: $selectedItem, matching: self.newPickerFilter)
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
