//
//  MatrixMessage.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 10/28/20.
//

import Foundation
import MatrixSDK
import DictionaryCoding

class MatrixMessage: ObservableObject, Identifiable {
    let id: String
    private let mxevent: MXEvent
    let room: MatrixRoom
    let matrix: MatrixInterface
    var content: MatrixMsgContent? // Use the DictionaryCoding thing to decode event.content
    var queue: DispatchQueue
    var downloadingThumbnail: Bool = false
    var downloadingAvatar: Bool = false
    private var cachedThumbnailImage: UIImage?
    private var cachedAvatarImage: UIImage?
    
    //init(from mxevent: MXEvent, on matrix: MatrixInterface) {
    init(from mxevent: MXEvent, in room: MatrixRoom) {
        self.id = mxevent.eventId
        self.room = room
        self.mxevent = mxevent
        self.matrix = room.matrix
        self.queue = DispatchQueue(label: mxevent.eventId, qos: .background)
        
        assert(self.mxevent.type == "m.room.message")
        
        let decoder = DictionaryDecoder()
        // swiftlint:disable:next force_try
        try! self.content = decoder.decode(MatrixMsgContent.self, from: mxevent.content)
        
    }
    
    var isEncrypted: Bool {
        self.mxevent.isEncrypted
    }
    
    var sender: String {
        self.mxevent.sender
    }
    
    var type: String {
        self.mxevent.content["msgtype"] as? String ?? "unknown"
    }
    
    var avatarURL: String? {
        /* // Disabling room-local profiles for now.  Maybe it will come back later.
        // First look in the Room.  Do we have a room-local avatar for this user?
        if let roomLocalUrl = room.roomLocalAvatarUrls[userId] {
            return roomLocalUrl
        }
        */
        // If we don't have a specific avatar for this room, try to look up
        // the user in our local MatrixUser cache.  If we've seen this user
        // before, fall back to using their regular global avatar (maybe nil)
        guard let userId = mxevent.sender,
           let user = matrix.getUser(userId: userId) else {
            // If we don't know this user, and there's no room-local avatar,
            // then we don't know anything about what their avatar might be.
            // We just know that we don't have one for them right now.
            return nil
        }
        return user.avatarURL
    }
    
    // FIXME why aren't we simply falling through to the MatrixUser here?
    var avatarImage: UIImage? {
        // Do we already have the image here in our little one-off cache?
        if let img = self.cachedAvatarImage {
            return img
        }
        // Nope, don't have it already cached
        // Do we have a URL where we can find it?
        guard let url = self.avatarURL else {
            // No?  Then we're SOL.
            return nil
        }
        // OK, we have the URL but not the image
        // Try to look up the image in the Matrix SDK's cache
        //print("Getting avatar image for event \(self.id) at \(url)")
        guard let cached_image = self.matrix.getCachedImage(mxURI: url) else {
            self.queue.sync(flags: .barrier) {
                if !self.downloadingAvatar {
                    self.downloadingAvatar = true
                    self.matrix.downloadImage(mxURI: url) { downloadedImage in
                        //print("Fetched avatar image for event \(self.id)")
                        self.cachedAvatarImage = downloadedImage
                        self.objectWillChange.send()
                        // Now, next time when SwiftUI comes back to re-render,
                        // it will find the image in the cache.
                        // No need to do anything else right now.
                        self.downloadingAvatar = false
                    }
                } else {
                    print("MESSAGE\tAvatar is already being downloaded; Doing nothing")
                }
            }
            // Return nil for now, knowing that soon we will get the image
            // and then SwiftUI can re-render us with it
            return nil
        }
        //print("Using cached image for event \(self.id) avatar")
        return cached_image
    }
    
    var thumbnailURL: URL? {
        switch self.content {
        case .image(let imageContent):
            return imageContent.info.thumbnail_url ?? imageContent.url
        case .video(let videoContent):
            return videoContent.info.thumbnail_url
        case .location(let locationContent):
            return locationContent.info.thumbnail_url
        case .audio:
            // Apparently there's no thumbnail for an m.audio message :(
            return nil
        default:
            return nil
        }
    }
    
    var thumbnailFile: mEncryptedFile? {
        if !isEncrypted {
            return nil
        }
        switch(self.content) {
        case nil:
            return nil
        case .image(let imageContent):
            return imageContent.info.thumbnail_file
        case .video(let videoContent):
            return videoContent.info.thumbnail_file
        case .file(let fileContent):
            return fileContent.info.thumbnail_file
        default:
            return nil
        }
    }
    
    var encryptedFile: mEncryptedFile? {
        if !isEncrypted {
            return nil
        }
        switch(self.content) {
        case nil:
            return nil
        case .image(let imageContent):
            return imageContent.info.file
        case .audio(let audioContent):
            return audioContent.file
        case .video(let videoContent):
            return videoContent.file
        case .file(let fileContent):
            return fileContent.file
        default:
            return nil
        }
    }
    
        
    var thumbnailImage: UIImage? {
        // Do we have the image already in our little one-off cache?
        if let img = self.cachedThumbnailImage {
            return img
        }
        // Do we have an encrypted thumbnail?
        if let fileInfo = self.thumbnailFile ?? self.encryptedFile {
            //  Handle encrypted case
            print("THUMB\tImage is encrypted")
            // First, let's see if we've already downloaded and decrypted
            guard let cachedImage = matrix.getCachedEncryptedImage(mxURI: fileInfo.url.absoluteString) else {
                queue.sync(flags: .barrier) {
                    if !self.downloadingThumbnail {
                        self.downloadingThumbnail = true
                        print("THUMB\tStarting download")
                        self.matrix.downloadEncryptedImage(fileinfo: fileInfo) { response in
                            switch response {
                            case .success(let downloadedImage):
                                print("THUMB\tDownload success")
                                self.cachedThumbnailImage = downloadedImage
                                DispatchQueue.main.async {
                                    // Tell SwiftUI to re-draw
                                    self.objectWillChange.send()
                                }
                            default:
                                print("THUMB\tDownload failed :(")
                            }
                            self.downloadingThumbnail = false
                        }
                    } else {
                        print("THUMB\tAlready downloading; Doing nothing")
                    }
                }
                return nil
            }
            return cachedImage
        }
        else {
            // Un-encrypted case
            if let url = self.thumbnailURL {
                guard let cached_image = matrix.getCachedImage(mxURI: url.absoluteString) else {
                    // Feels like we need a DispatchQueue here...
                    //queue.async {
                        //if !self.downloadingThumbnail {
                            print("THUMB\tDownloading for [\(self.id)]")
                            //self.downloadingThumbnail = true
                            self.matrix.downloadImage(mxURI: url.absoluteString) { downloadedImage in
                                self.cachedThumbnailImage = downloadedImage
                                //DispatchQueue.main.sync {
                                    self.objectWillChange.send()
                                //}
                                print("THUMB\tFetched thumbnail image for event \(self.id)")
                                //self.downloadingThumbnail = false
                            }
                        //}
                    //}
                    return nil
                }
                print("Using cached image for event \(self.id)")
                return cached_image
            }
            else {
                return nil
            }
        }
        
    }
    
    lazy var timestamp: Date = {
        let seconds = self.mxevent.originServerTs/1000
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }()
    
}

extension MatrixMessage: Equatable {
    // For Equatable
    static func == (lhs: MatrixMessage, rhs: MatrixMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MatrixMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
