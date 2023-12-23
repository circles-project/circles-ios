//  Copyright 2022, 2023 FUTO Holdings Inc
//
//  PostComposer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/4/20.
//

import SwiftUI
import PhotosUI
import QuickLookThumbnailing
import Matrix

struct PostComposer: View {
    @ObservedObject var room: Matrix.Room
    @EnvironmentObject var appSession: CirclesApplicationSession
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
        case loadingVideo(Task<Void,Error>)
        case cloudImage(Matrix.mImageContent, UIImage?)
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
        
        var isLoading: Bool {
            switch self {
            case .loadingVideo:
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
    //@State private var showPicker = false
    @State private var showNewPicker = false
    @State private var newPickerFilter: PHPickerFilter = .images
    //@State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var inProgress = false
    
    @State private var selectedImageContent: Matrix.mImageContent?
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false

    enum ImageSourceType: String, Identifiable {
        case cloud
        case camera
        
        var id: String {
            self.rawValue
        }
    }
    
    //@State private var imageSourceType: ImageSourceType?
    @State private var showPickerOfType: ImageSourceType?
    @State var selectedItem: PhotosPickerItem? = nil
    
    init(room: Matrix.Room,
         parent: Matrix.Message? = nil,
         editing: Matrix.Message? = nil
    ) {
        self.room = room
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
    
    private func send() async throws {
        // Post the message
        
        switch(self.messageState) {
            
        case .text:
            if let parentMessage = self.parent {
                let replyEventId = try await room.sendText(text: self.newMessageText, inReplyTo: parentMessage)
                print("REPLY\tSent m.text reply with eventId = \(replyEventId)")
            } else if let oldMessage = self.editing {
                let replacementEventId = try await room.sendText(text: self.newMessageText, replacing: oldMessage)
                print("EDIT\tSent edited m.text with eventId = \(replacementEventId)")
            } else {
                let newEventId = try await room.sendText(text: self.newMessageText)
                print("COMPOSER\tSent m.text with eventId = \(newEventId)")
            }
            self.presentation.wrappedValue.dismiss()

            
        case .newImage(let img):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil

            if let parentMessage = self.parent {
                let replyEventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true, inReplyTo: parentMessage)
                print("COMPOSER\tSent m.image reply with eventId = \(replyEventId)")
            } else if let oldMessage = self.editing {
                let replacementEventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true, replacing: oldMessage)
                print("EDIT\tSent edited m.image with eventId = \(replacementEventId)")
            } else {
                let newEventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true)
                print("COMPOSER\tSent m.image with eventId = \(newEventId)")
            }
            self.presentation.wrappedValue.dismiss()
            
            
        case .loadingVideo:
            print("COMPOSER\tError: Can't send until the video is done loading")
            
            
        case .newVideo(let movie, let thumbnail):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            
            if let parentMessage = self.parent {
                let replyEventId = try await room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption, inReplyTo: parentMessage)
                print("COMPOSER\tSent m.video reply with eventId = \(replyEventId)")
            } else if let oldMessage = self.editing {
                let eventId = try await room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption, replacing: oldMessage)
                print("COMPOSER\tSent edited m.video with eventId = \(eventId)")
            } else {
                let newEventId = try await room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption)
                print("COMPOSER\tSent m.video with eventId = \(newEventId)")
            }
            self.presentation.wrappedValue.dismiss()
            
        case .oldImage(let oldImageContent, _):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            let newContent = Matrix.mImageContent(oldImageContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent edited m.image with new eventId = \(eventId)")
            self.presentation.wrappedValue.dismiss()
            
        case .cloudImage(let cloudImageContent, _):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            let newContent = Matrix.mImageContent(cloudImageContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent cloud m.image with new eventId = \(eventId)")
            self.presentation.wrappedValue.dismiss()
            
        case .oldVideo(let oldVideoContent, _):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            let newContent = Matrix.mVideoContent(oldVideoContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent edited m.video with new eventId = \(eventId)")
            self.presentation.wrappedValue.dismiss()
            
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
                    //self.imageSourceType = .camera
                    //self.showPicker = true
                    self.showPickerOfType = .camera
                }) {
                    Label("Take a new photo", systemImage: "camera.fill")
                }
                Button(action: {
                    //self.imageSourceType = .cloud
                    //self.showPicker = true
                    self.showPickerOfType = .cloud
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
                Label("Cancel", systemImage: "xmark")
                    //.foregroundColor(.red)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
            }
            .buttonStyle(.bordered)
            .padding(3)

            AsyncButton(action: {
                try await send()
            }) {
                Label("Send", systemImage: "paperplane.fill")
                    .disabled(inProgress)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
            }
            .buttonStyle(.bordered)
            .disabled(self.messageState.isLoading)
            .padding(3)

        }
        .padding(.leading)
    }
    
    @ViewBuilder
    var thumbnail: some View {
        switch(messageState) {
            
        case .text:
            if debugMode {
                Text("Editing")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            
        case .newImage(let image):
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
            
        case .loadingVideo(let task):
            ZStack {
                Color.secondaryBackground
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: {
                            print("COMPOSER\tCanceling loading video")
                            task.cancel()
                            self.messageState = .text
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                        }
                        .disabled(task.isCancelled)
                    }
                
                ProgressView("Loading video...")
            }
            
        case .newVideo(let movie, let thumbnail):
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
            
        case .cloudImage(let cloudImageContent, let thumbnail):
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
                                if let file = cloudImageContent.thumbnail_file ?? cloudImageContent.file {
                                    let data = try await self.room.session.downloadAndDecryptData(file)
                                    let thumbnail = UIImage(data: data)
                                    await MainActor.run {
                                        self.messageState = .cloudImage(cloudImageContent, thumbnail)
                                    }
                                } else if let mxc = cloudImageContent.thumbnail_url ?? cloudImageContent.url {
                                    let data = try await self.room.session.downloadData(mxc: mxc)
                                    let thumbnail = UIImage(data: data)
                                    await MainActor.run {
                                        self.messageState = .cloudImage(cloudImageContent, thumbnail)
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
            
        case .oldImage(let originalImageContent, let thumbnail):
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
            
        case .oldVideo(let originalVideoContent, let thumbnail):
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
        }
    }
        
        
    private func handleItemChanged(_ newItem: PhotosPickerItem?) {
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
                    let task = Task {
                        if let movie = try? await newItem?.loadTransferable(type: Movie.self) {
                            print("PICKER User picked a video: \(movie.url.absoluteString)")

                            // It can take soooo long to load the video that the user might have given up on us
                            if !Task.isCancelled {
                                let thumb = try await movie.loadThumbnail()
                                
                                // Check again to make sure that the user didn't give up while we were loading the thumbnail
                                if !Task.isCancelled {
                                    await MainActor.run {
                                        self.messageState = .newVideo(movie, thumb)
                                    }
                                }
                            }

                        } else {
                            print("PICKER Failed to get a new video")
                            if !Task.isCancelled {
                                await MainActor.run {
                                    self.messageState = .text
                                }
                            }
                        }
                    }
                    await MainActor.run {
                        self.messageState = .loadingVideo(task)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            let myUserId = room.session.creds.userId
            let myUser = room.session.getUser(userId: myUserId)
            MessageAuthorHeader(user: myUser)
                .padding()

            ZStack {
                VStack(alignment: .center, spacing: 2) {
                    
                    thumbnail
                    
                    TextEditor(text: $newMessageText)
                    //.frame(height: 90)
                    //.foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(10)
                        .frame(minHeight: 120)
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
                handleItemChanged(newItem)
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
        .sheet(item: $showPickerOfType, content: { type in
            switch type {
            case .camera:
                ImagePicker(selectedImage: $newImage, sourceType: .camera)
                    .onAppear {
                        print("Showing picker of type = \(self.showPickerOfType?.rawValue ?? "nil") -- type = \(type)")
                    }
            case .cloud:
                CloudImagePicker(galleries: appSession.galleries, selected: self.$selectedImageContent) { content, image in
                    self.messageState = .cloudImage(content, image)
                }
                    .onAppear {
                        print("Showing picker of type = \(self.showPickerOfType?.rawValue ?? "nil") -- type = \(type)")
                    }
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
