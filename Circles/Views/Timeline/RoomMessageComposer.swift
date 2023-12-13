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
    @AppStorage("debugMode") var debugMode: Bool = false

    var parent: Matrix.Message?
    var editing: Matrix.Message?
    
    enum MessageState {
        case text                // For m.text it doesn't matter if the content is old or new, since there's no complicated media to juggle
        case newImage(UIImage)
        case newVideo(Movie, UIImage)
        case oldImage(Matrix.mImageContent, UIImage?)
        case oldVideo(Matrix.mVideoContent, UIImage?)
        
        var isText: Bool {
            if case .text = self {
                return true
            } else {
                return false
            }
        }
        
        var isImage: Bool {
            switch self {
            case .newImage, .oldImage:
                return true
            default:
                return false
            }
        }
        
        var isVideo: Bool {
            switch self {
            case .newVideo, .oldVideo:
                return true
            default:
                return false
            }
        }
    }
    @State private var messageState: MessageState
    private let relatesTo: mRelatesTo?
    //@State private var newMessageType: String = M_TEXT
    @State private var newMessageText: String
    @State private var newImage: UIImage? = nil
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
        case camera
    }
    
    @State private var imageSourceType: ImageSourceType = .camera
    @State var selectedItem: PhotosPickerItem? = nil
    
    init(room: Matrix.Room,
         galleries: ContainerRoom<GalleryRoom>,
         parent: Matrix.Message? = nil,
         editing: Matrix.Message? = nil
    ) {
        self.room = room
        self.galleries = galleries
        self.parent = parent
        self.editing = editing

        // OK because Apple sucks, we have to be very careful in how we initialize @State vars here
        // I guess they really just want us to use the compiler-generated init()
        // But if we don't, the rules are:
        //   * We can't just say self.foo = Foo().  We have to use self._foo = State(wrappedValue: Foo()) or wrappedValue = Foo.xyz etc
        //   * We can only initialize each @State var *once*.  If we try to write to it a 2nd time, it will do nothing.
        // Source: https://forums.swift.org/t/assignment-to-state-var-in-init-doesnt-do-anything-but-the-compiler-gened-one-works/35235
        
        // If we're editing an existing message, then we need to pre-fill all of our stuff based on it
        if let originalMessage = editing,
           let originalContent = originalMessage.content as? Matrix.MessageContent
        {
            self.relatesTo = mRelatesTo(relType: M_REPLACE, eventId: originalMessage.eventId)
            
            print("COMPOSER\tLoading original content")
            switch originalContent.msgtype {
            case M_IMAGE:
                // Setup our initial state to be a simple copy of the old m.image
                if let originalImageContent = originalContent as? Matrix.mImageContent {
                    self._newMessageText = State(wrappedValue: originalImageContent.caption ?? "")
                    self._messageState = State(wrappedValue: MessageState.oldImage(originalImageContent, nil))
                } else {
                    // Default to an m.text message
                    self._newMessageText = State(wrappedValue: "")
                    self._messageState = State(wrappedValue: MessageState.text)
                }

            case M_VIDEO:
                // Setup our initial state to be a simple copy of the old m.image
                if let originalVideoContent = originalContent as? Matrix.mVideoContent {
                    self._newMessageText = State(wrappedValue: originalVideoContent.caption ?? "")
                    self._messageState = State(wrappedValue: MessageState.oldVideo(originalVideoContent, nil))
                } else {
                    // Default to an m.text message
                    self._newMessageText = State(wrappedValue: "")
                    self._messageState = State(wrappedValue: MessageState.text)
                }

            default:
                print("COMPOSER\tSetting message to text: \(originalContent.body)")
                self._newMessageText = State(wrappedValue: originalContent.body)
                self._messageState = State(wrappedValue: MessageState.text)
                print("COMPOSER\tText is: \(self.newMessageText)")
            }
        } else {
            
            if let parentMessage = parent {
                self.relatesTo = mRelatesTo(relType: M_THREAD, eventId: parentMessage.eventId)
            } else {
                self.relatesTo = nil
            }
            
            // Default to an m.text message
            self._newMessageText = State(wrappedValue: "")
            self._messageState = State(wrappedValue: MessageState.text)
        }
    }
        
    var buttonBar: some View {
        HStack(spacing: 5.0) {
            Button(action: {
                self.messageState = .text
            }) {
                Image(systemName: "doc.plaintext")
                    .scaleEffect(1.5)
            }
            .disabled(messageState.isText || editing != nil)
            .padding(1)

            Menu(content: {
                Button(action: {
                    self.newPickerFilter = .images
                    self.showNewPicker = true
                }) {
                    Label("Upload a photo", systemImage: "photo.fill")
                }
                Button(action: {
                    self.imageSourceType = .camera
                    self.showPicker = true
                }) {
                    Label("Take a new photo", systemImage: "camera.fill")
                }
                Button(action: {
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
            .disabled(messageState.isImage || editing != nil)
            .padding(1)

            
            Menu(content: {
                Button(action: {
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
            .disabled(messageState.isVideo || editing != nil)
            .padding(1)

            
            Spacer()
            Button(role: .destructive, action: {
                //self.isPresented = false
                self.presentation.wrappedValue.dismiss()
                self.newMessageText = ""
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
                // Post the message
                
                switch(self.messageState) {
                    
                case .text:
                    if let parentMessage = self.parent {
                        print("REPLY\tSending threaded reply")
                        let replyEventId = try await parentMessage.room.sendReply(to: parentMessage.event, text: self.newMessageText, threaded: true)
                        print("REPLY\tSent eventId = \(replyEventId)")
                        self.presentation.wrappedValue.dismiss()
                    } else {
                        let eventId = try await self.room.sendText(text: self.newMessageText, replacing: self.editing)
                        print("COMPOSER\tSent m.text with eventId = \(eventId)")
                        self.presentation.wrappedValue.dismiss()
                    }
                    
                case .newImage(let img):
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let eventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true, replacing: self.editing)
                    print("COMPOSER\tSent m.image with eventId = \(eventId)")
                    self.presentation.wrappedValue.dismiss()
                    
                    
                case .newVideo(let movie, let thumbnail):
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let eventId = try await self.room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption, replacing: self.editing)
                    print("COMPOSER\tSent m.video with eventId = \(eventId)")
                    self.presentation.wrappedValue.dismiss()
                    
                case .oldImage(let oldImageContent, _):
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let newContent = Matrix.mImageContent(oldImageContent, caption: caption, relatesTo: self.relatesTo)
                    let eventId = try await self.room.sendMessage(content: newContent)
                    print("COMPOSER\tSent edited m.image with new eventId = \(eventId)")
                    self.presentation.wrappedValue.dismiss()
                    
                case .oldVideo(let oldVideoContent, _):
                    let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
                    let newContent = Matrix.mVideoContent(oldVideoContent, caption: caption, relatesTo: self.relatesTo)
                    let eventId = try await self.room.sendMessage(content: newContent)
                    print("COMPOSER\tSent edited m.video with new eventId = \(eventId)")
                    self.presentation.wrappedValue.dismiss()
                    
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
                switch(messageState) {
                    
                case .text:
                    VStack(alignment: .center, spacing: 2) {
                        if debugMode {
                            Text("Editing")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        TextEditor(text: $newMessageText)
                        //.frame(height: 90)
                        //.foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .lineLimit(10)
                    }
                    
                case .newImage(let image):
                    VStack(alignment: .center, spacing: 2) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(alignment: .bottomTrailing) {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Image(systemName: "pencil.circle.fill")
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 30))
                                        .foregroundColor(.accentColor)
                                }
                            }
                        TextEditor(text: $newMessageText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(5)
                    }
                    
                case .newVideo(let movie, let thumbnail):
                    VStack(alignment: .center, spacing: 2) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(alignment: .bottomTrailing) {
                                PhotosPicker(selection: $selectedItem, matching: .videos) {
                                    Image(systemName: "pencil.circle.fill")
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 30))
                                        .foregroundColor(.accentColor)
                                }
                            }
                        TextEditor(text: $newMessageText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(5)
                    }
                    
                case .oldImage(let originalImageContent, let thumbnail):
                    VStack(alignment: .center, spacing: 2) {
                        if let image = thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(alignment: .bottomTrailing) {
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        Image(systemName: "pencil.circle.fill")
                                            .symbolRenderingMode(.multicolor)
                                            .font(.system(size: 30))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                        } else {
                            ZStack {
                                Image(systemName: "photo.artframe")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                ProgressView()
                                    .onAppear {
                                        // Start fetching the thumbnail
                                        Task {
                                            if let file = originalImageContent.thumbnail_file ?? originalImageContent.file {
                                                let data = try await self.room.session.downloadAndDecryptData(file)
                                                let thumbnail = UIImage(data: data)
                                                await MainActor.run {
                                                    self.messageState = .oldImage(originalImageContent, thumbnail)
                                                }
                                            } else if let mxc = originalImageContent.thumbnail_url ?? originalImageContent.url {
                                                let data = try await self.room.session.downloadData(mxc: mxc)
                                                let thumbnail = UIImage(data: data)
                                                await MainActor.run {
                                                    self.messageState = .oldImage(originalImageContent, thumbnail)
                                                }
                                            }
                                        }
                                    }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Image(systemName: "pencil.circle.fill")
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 30))
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        TextEditor(text: $newMessageText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(5)
                    }
                    
                case .oldVideo(let originalVideoContent, let thumbnail):
                    VStack(alignment: .center, spacing: 2) {
                        if let image = thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(alignment: .bottomTrailing) {
                                    PhotosPicker(selection: $selectedItem, matching: .videos) {
                                        Image(systemName: "pencil.circle.fill")
                                            .symbolRenderingMode(.multicolor)
                                            .font(.system(size: 30))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                        } else {
                            ZStack {
                                Image(systemName: "photo.artframe")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                                ProgressView()
                                    .onAppear {
                                        // Start fetching the thumbnail
                                        Task {
                                            if let file = originalVideoContent.thumbnail_file {
                                                let data = try await self.room.session.downloadAndDecryptData(file)
                                                let thumbnail = UIImage(data: data)
                                                await MainActor.run {
                                                    self.messageState = .oldVideo(originalVideoContent, thumbnail)
                                                }
                                            } else if let mxc = originalVideoContent.thumbnail_url {
                                                let data = try await self.room.session.downloadData(mxc: mxc)
                                                let thumbnail = UIImage(data: data)
                                                await MainActor.run {
                                                    self.messageState = .oldVideo(originalVideoContent, thumbnail)
                                                }
                                            }
                                        }
                                    }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                PhotosPicker(selection: $selectedItem, matching: .videos) {
                                    Image(systemName: "pencil.circle.fill")
                                        .symbolRenderingMode(.multicolor)
                                        .font(.system(size: 30))
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        TextEditor(text: $newMessageText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(5)
                    }
                    
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
                        if self.newPickerFilter == .images {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data)
                            {
                                await MainActor.run {
                                    self.messageState = .newImage(img)
                                }
                            } else {
                                print("PICKER Failed to get a new image")
                            }
                            return
                        }
                        
                        if self.newPickerFilter == .videos {
                            if let movie = try? await newItem?.loadTransferable(type: Movie.self) {
                                print("PICKER User picked a video: \(movie.url.absoluteString)")
                                let thumb = try await movie.loadThumbnail()
                                await MainActor.run {
                                    self.messageState = .newVideo(movie, thumb)
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
            case .camera:
                ImagePicker(selectedImage: $newImage, sourceType: .camera)
            case .cloud:
                CloudImagePicker(galleries: galleries, selectedImage: self.$newImage)
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
