//
//  ComposerViewModel.swift
//  Circles
//
//  Created by Charles Wright on 8/27/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Matrix
import Dispatch

public class ComposerViewModel: ObservableObject {
    @Published var text: String
    @Published var selectedItem: PhotosPickerItem? = nil {
        didSet {
            if let selectedItem {
                self.handleItemChanged(selectedItem)
            }
        }
    }
    
    
    var filter: PHPickerFilter
    var room: Matrix.Room
    var parent: Matrix.Message?
    var editing: Matrix.Message?
    
    var relatesTo: mRelatesTo?
    
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
        
        var thumbnail: UIImage? {
            switch self {
            case .text:
                return nil
            case .oldImage(_, let img):
                return img
            case .oldVideo(_, let img):
                return img
            case .loadingVideo(_):
                return nil
            case .newImage(let img):
                return img
            case .newVideo(_, let img):
                return img
            }
        }
    }
    @Published var messageState: MessageState
    
    public init(room: Matrix.Room,
                parent: Matrix.Message? = nil,
                editing: Matrix.Message? = nil
    ) {
        self.selectedItem = nil
        self.filter = .images
        self.room = room
        self.parent = parent
        self.editing = editing
        
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
                    self.text = existingImageContent.caption ?? ""
                    self.messageState = MessageState.oldImage(existingImageContent, nil)
                } else {
                    // Default to an m.text message
                    self.text = ""
                    self.messageState = MessageState.text
                }
                
            case M_VIDEO:
                // Setup our initial state to be a simple copy of the old m.video
                if let existingVideoContent = existingContent as? Matrix.mVideoContent {
                    self.text = existingVideoContent.caption ?? ""
                    self.messageState = MessageState.oldVideo(existingVideoContent, nil)
                } else {
                    // Default to an m.text message
                    self.text = ""
                    self.messageState = MessageState.text
                }
                
            default:
                print("COMPOSER\tSetting message to text: \(existingContent.body)")
                self.text = existingContent.body
                self.messageState = MessageState.text
                print("COMPOSER\tText is: \(self.text)")
            }
        } else {
            if let parentMessage = parent {
                self.relatesTo = mRelatesTo(relType: M_THREAD, eventId: parentMessage.eventId)
            } else {
                self.relatesTo = nil
            }
            
            // Default to an m.text message
            self.text = ""
            self.messageState = MessageState.text
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
    
    public func send() async throws -> EventId {
        // Post the message
        switch(self.messageState) {
        case .text:
            if self.text.isEmpty {
                await ToastPresenter.shared.showToast(message: "You can not send an empty post")
            } else {
                if let parentMessage = self.parent {
                    let replyEventId = try await room.sendText(text: self.text, inReplyTo: parentMessage)
                    print("REPLY\tSent m.text reply with eventId = \(replyEventId)")
                    return replyEventId
                } else if let oldMessage = self.editing {
                    let replacementEventId = try await room.sendText(text: self.text, replacing: oldMessage)
                    print("EDIT\tSent edited m.text with eventId = \(replacementEventId)")
                    return replacementEventId
                } else {
                    let newEventId = try await room.sendText(text: self.text)
                    print("COMPOSER\tSent m.text with eventId = \(newEventId)")
                    return newEventId
                }
            }
            
        case .newImage(let img):
            let caption: String? = !self.text.isEmpty ? self.text : nil
            
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
            throw CirclesError("Can't send until video is loaded")
            
        case .newVideo(let movie, let thumbnail):
            let caption: String? = !self.text.isEmpty ? self.text : nil
            
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
            let caption: String? = !self.text.isEmpty ? self.text : nil
            let newContent = Matrix.mImageContent(oldImageContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent edited m.image with new eventId = \(eventId)")
            return eventId
            
        case .oldVideo(let oldVideoContent, _):
            let caption: String? = !self.text.isEmpty ? self.text : nil
            let newContent = Matrix.mVideoContent(oldVideoContent, caption: caption, relatesTo: self.relatesTo)
            let eventId = try await self.room.sendMessage(content: newContent)
            print("COMPOSER\tSent edited m.video with new eventId = \(eventId)")
            return eventId
            
        }
        
        print("COMPOSER\tFailed to send - switch fell through")
        throw CirclesError("Failed to send")
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
    
    public func handleItemChanged(_ newItem: PhotosPickerItem?) {
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
                if self.filter == .images {
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
                
                if self.filter == .videos {
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
    
    @MainActor
    public func reset() async {
        self.text = ""
        self.messageState = .text
    }
}
