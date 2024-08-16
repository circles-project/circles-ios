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
    var room: Matrix.Room
    @EnvironmentObject var timelineViewModel: TimelineViewModel
    @EnvironmentObject var appSession: CirclesApplicationSession
    //@Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentation

    var parent: Matrix.Message?
    var editing: Matrix.Message?
    
    enum FocusField {
        case editor
    }
    @FocusState var focus: FocusField?
    
    enum MessageState {
        case text                // For m.text it doesn't matter if the content is old or new, since there's no complicated media to juggle
        case newImage(UIImage)
        case newVideo(Movie, UIImage)
        case loadingVideo(Task<Void,Error>)
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
        if let existingMessage = editing?.replacement ?? editing,                      // If we're editing an already-edited message, start with the most recent version
           let existingContent = existingMessage.content as? Matrix.MessageContent
        {
            self.relatesTo = mRelatesTo(relType: M_REPLACE, eventId: existingMessage.eventId)
            
            print("COMPOSER\tLoading original content")
            switch existingContent.msgtype {
            case M_IMAGE:
                // Setup our initial state to be a simple copy of the old m.image
                if let existingImageContent = existingContent as? Matrix.mImageContent {
                    self._newMessageText = State(wrappedValue: existingImageContent.caption ?? "")
                    self._messageState = State(wrappedValue: MessageState.oldImage(existingImageContent, nil))
                } else {
                    // Default to an m.text message
                    self._newMessageText = State(wrappedValue: "")
                    self._messageState = State(wrappedValue: MessageState.text)
                }

            case M_VIDEO:
                // Setup our initial state to be a simple copy of the old m.image
                if let existingVideoContent = existingContent as? Matrix.mVideoContent {
                    self._newMessageText = State(wrappedValue: existingVideoContent.caption ?? "")
                    self._messageState = State(wrappedValue: MessageState.oldVideo(existingVideoContent, nil))
                } else {
                    // Default to an m.text message
                    self._newMessageText = State(wrappedValue: "")
                    self._messageState = State(wrappedValue: MessageState.text)
                }

            default:
                print("COMPOSER\tSetting message to text: \(existingContent.body)")
                self._newMessageText = State(wrappedValue: existingContent.body)
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
    
    private func downloadImageData(content: Matrix.mImageContent) async throws -> (Data, Data?) {
        var mainData: Data
        if let mainFile = content.file {
            mainData = try await room.session.downloadAndDecryptData(mainFile)
        } else if let mainUrl = content.url {
            mainData = try await room.session.downloadData(mxc: mainUrl)
        } else {
            print("Couldn't download main image data")
            throw CirclesError("Couldn't download main image data")
        }
        
        var thumbnailData: Data?
        if let thumbnailFile = content.thumbnail_file {
            thumbnailData = try await room.session.downloadAndDecryptData(thumbnailFile)
        } else if let thumbnailUrl = content.thumbnail_url {
            thumbnailData = try await room.session.downloadData(mxc: thumbnailUrl)
        }
        
        return (mainData, thumbnailData)
    }
    
    private func repostImageContent(_ oldContent: Matrix.mImageContent, caption: String? = nil) async throws -> EventId {
        let (mainData, thumbnailData) = try await downloadImageData(content: oldContent)
        
        if room.isEncrypted {
            let mainFile: Matrix.mEncryptedFile = try await room.session.encryptAndUploadData(plaintext: mainData, contentType: oldContent.info.mimetype)
            print("COMPOSER\tRe-uploaded encrypted image to new URL \(mainFile.url)")
            var thumbnailFile: Matrix.mEncryptedFile?
            if let thumbData = thumbnailData,
               let thumbInfo = oldContent.thumbnail_info
            {
                thumbnailFile = try await room.session.encryptAndUploadData(plaintext: thumbData, contentType: thumbInfo.mimetype)
                print("COMPOSER\tRe-uploaded encrypted thumbnail to new URL \(thumbnailFile!.url)")
            }
            
            let info = Matrix.mImageInfo(oldContent.info, thumbnail_url: nil, thumbnail_file: thumbnailFile, thumbnail_info: oldContent.thumbnail_info)
            let newContent = Matrix.mImageContent(oldContent, caption: caption, file: mainFile, info: info, url: nil)
            
            let eventId = try await room.sendMessage(content: newContent)
            return eventId
            
        } else { // Not encrypted
            let mainUrl = try await room.session.uploadData(data: mainData, contentType: oldContent.info.mimetype)
            var thumbnailUrl: MXC?
            if let thumbData = thumbnailData,
               let thumbInfo = oldContent.thumbnail_info
            {
                thumbnailUrl = try await room.session.uploadData(data: thumbData, contentType: thumbInfo.mimetype)
            }
            
            let info = Matrix.mImageInfo(oldContent.info, thumbnail_url: thumbnailUrl, thumbnail_file: nil, thumbnail_info: oldContent.thumbnail_info)
            let newContent = Matrix.mImageContent(oldContent, file: nil, info: info, url: mainUrl)
            
            let eventId = try await room.sendMessage(content: newContent)
            return eventId
        }
    }
    
    private func send() async throws -> EventId? {
        // Post the message
        switch(self.messageState) {
        case .text:
            if self.newMessageText.isEmpty {
                await ToastPresenter.shared.showToast(message: "Cannot send an empty post")
                return nil
            } else {
                if let parentMessage = self.parent {
                    let replyEventId = try await room.sendText(text: self.newMessageText, inReplyTo: parentMessage)
                    print("REPLY\tSent m.text reply with eventId = \(replyEventId)")
                    return replyEventId
                } else if let oldMessage = self.editing {
                    let replacementEventId = try await room.sendText(text: self.newMessageText, replacing: oldMessage)
                    print("EDIT\tSent edited m.text with eventId = \(replacementEventId)")
                    return replacementEventId
                } else {
                    let newEventId = try await room.sendText(text: self.newMessageText)
                    print("COMPOSER\tSent m.text with eventId = \(newEventId)")
                    return newEventId
                }
            }
            
        case .newImage(let img):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil

            if let parentMessage = self.parent {
                let replyEventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true, inReplyTo: parentMessage)
                print("COMPOSER\tSent m.image reply with eventId = \(replyEventId)")
                return replyEventId
            } else if let oldMessage = self.editing {
                let replacementEventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true, replacing: oldMessage)
                print("EDIT\tSent edited m.image with eventId = \(replacementEventId)")
                return replacementEventId
            } else {
                let newEventId = try await self.room.sendImage(image: img, caption: caption, withBlurhash: false, withThumbhash: true)
                print("COMPOSER\tSent m.image with eventId = \(newEventId)")
                return newEventId
            }
            
        case .loadingVideo:
            print("COMPOSER\tError: Can't send until the video is done loading")
            await ToastPresenter.shared.showToast(message: "Cannot send yet - Video is still loading")
            return nil
            
        case .newVideo(let movie, let thumbnail):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            
            if let parentMessage = self.parent {
                let replyEventId = try await room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption, inReplyTo: parentMessage)
                print("COMPOSER\tSent m.video reply with eventId = \(replyEventId)")
                return replyEventId
            } else if let oldMessage = self.editing {
                let eventId = try await room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption, replacing: oldMessage)
                print("COMPOSER\tSent edited m.video with eventId = \(eventId)")
                return eventId
            } else {
                let newEventId = try await room.sendVideo(url: movie.url, thumbnail: thumbnail, caption: caption)
                print("COMPOSER\tSent m.video with eventId = \(newEventId)")
                return newEventId
            }
            
        case .oldImage(let oldImageContent, _):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            let newContent = Matrix.mImageContent(oldImageContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent edited m.image with new eventId = \(eventId)")
            return eventId
            
        case .oldVideo(let oldVideoContent, _):
            let caption: String? = !self.newMessageText.isEmpty ? self.newMessageText : nil
            let newContent = Matrix.mVideoContent(oldVideoContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent edited m.video with new eventId = \(eventId)")
            return eventId
        }
        
    }
    
    var oldMessageType: String? {
        switch messageState {
        case .text:
            return nil
        case .newImage(let uIImage):
            return nil
        case .newVideo(let movie, let uIImage):
            return nil
        case .loadingVideo(let task):
            return nil
        case .oldImage(let mImageContent, let uIImage):
            return M_IMAGE
        case .oldVideo(let mVideoContent, let uIImage):
            return M_VIDEO
        }
    }
        
    var buttonBar: some View {
        HStack(spacing: 5.0) {
            Menu(content: {
                if editing == nil || oldMessageType == M_VIDEO {
                    Button(action: {
                        self.newPickerFilter = .videos
                        self.showNewPicker = true
                        self.selectedItem = nil
                    }) {
                        Label("Choose Video", systemImage: "film")
                    }
                }
                if editing == nil || oldMessageType == M_IMAGE {
                    Button(action: {
                        self.newPickerFilter = .images
                        self.showNewPicker = true
                        self.selectedItem = nil
                    }) {
                        Label("Choose Photo", systemImage: "photo.fill")
                    }
                    Button(action: {
                        //self.imageSourceType = .camera
                        //self.showPicker = true
                        self.showPickerOfType = .camera
                    }) {
                        Label("New Photo", systemImage: "camera.fill")
                    }
                }
            },
            label: {
                Image(systemName: SystemImages.paperclip.rawValue)
                    .scaleEffect(1.5)
            })
            .disabled(oldMessageType == M_TEXT)
            .padding(1)
            
            Spacer()
            Button(role: .destructive, action: {
                //self.isPresented = false
                self.presentation.wrappedValue.dismiss()
                self.newMessageText = ""
            }) {
                Label("Cancel", systemImage: SystemImages.xmark.rawValue)
                    //.foregroundColor(.red)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 5)
            }
            .buttonStyle(.bordered)
            .padding(3)

            AsyncButton(action: {
                if let newEventId = try await send() {
                    let newScrollPosition: EventId
                    if let originalEventId = self.editing?.eventId {
                        newScrollPosition = originalEventId
                    } else {
                        newScrollPosition = newEventId
                    }
                    await MainActor.run {
                        timelineViewModel.scrollPosition = newScrollPosition
                    }
                    self.presentation.wrappedValue.dismiss()
                }
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
            if DebugModel.shared.debugMode {
                Text("Editing")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            
        case .newImage(let image):
            BasicImage(uiImage: image, aspectRatio: .fill)
                .frame(minWidth: 200, maxWidth: 800, minHeight: 200, maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .changeMediaOverlay(selectedItem: $selectedItem, matching: $newPickerFilter)
                .deleteMediaOverlay(selectedItem: $selectedItem, messageState: $messageState)

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
                            Image(systemName: SystemImages.xmarkCircleFill.rawValue)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                        }
                        .disabled(task.isCancelled)
                    }
                
                ProgressView("Loading video...")
            }
            
        case .newVideo(_, let thumbnail): // (let movie, let thumbnail)
            BasicImage(uiImage: thumbnail, aspectRatio: .fill)
                .frame(minWidth: 200, maxWidth: 800, minHeight: 200, maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .changeMediaOverlay(selectedItem: $selectedItem, matching: $newPickerFilter)
                .deleteMediaOverlay(selectedItem: $selectedItem, messageState: $messageState)
        
        case .oldImage(let originalImageContent, let thumbnail):
            if let image = thumbnail {
                BasicImage(uiImage: image)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .changeMediaOverlay(selectedItem: $selectedItem, matching: $newPickerFilter)
                    .deleteMediaOverlay(selectedItem: $selectedItem, messageState: $messageState)
            } else {
                ZStack {
                    BasicImage(systemName: SystemImages.photoArtframe.rawValue)
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
                .changeMediaOverlay(selectedItem: $selectedItem, matching: $newPickerFilter)
                .deleteMediaOverlay(selectedItem: $selectedItem, messageState: $messageState)
            }
            
        case .oldVideo(let originalVideoContent, let thumbnail):
            if let image = thumbnail {
                BasicImage(uiImage: image)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .changeMediaOverlay(selectedItem: $selectedItem, matching: $newPickerFilter)
                    .deleteMediaOverlay(selectedItem: $selectedItem, messageState: $messageState)
            } else {
                ZStack {
                    BasicImage(systemName: SystemImages.photoArtframe.rawValue)
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
                .changeMediaOverlay(selectedItem: $selectedItem, matching: $newPickerFilter)
                .deleteMediaOverlay(selectedItem: $selectedItem, messageState: $messageState)
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
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(10)
                        .focused($focus, equals: .editor)
                        .frame(minHeight: 120)
                        .onAppear {
                            self.focus = .editor
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
                ImagePicker(sourceType: .camera) { maybeImage in
                    if let image = maybeImage {
                        self.messageState = .newImage(image)
                    }
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
