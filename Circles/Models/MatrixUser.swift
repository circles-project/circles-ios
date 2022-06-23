//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MatrixUser.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/28/20.
//

import Foundation
import MatrixSDK

class MatrixUser: ObservableObject, Identifiable {
    private let mxuser: MXUser
    let userId: UserId
    var id: String { // For Identifiable
        userId.description
    }
    let matrix: MatrixSession
    var queue: DispatchQueue
    var downloadingAvatar: Bool
    var fetchingDisplayName: Bool
    
    init(from mxuser: MXUser, on matrix: MatrixSession) {
        print("Initializing a new MatrixUser for \(mxuser.userId!)")
        self.mxuser = mxuser
        self.userId = UserId(mxuser.userId)!
        self.matrix = matrix
        self.queue = DispatchQueue(label: mxuser.userId, qos: .background)
        self.downloadingAvatar = false
        self.fetchingDisplayName = false

        self.updateAvatar()
        mxuser.listen(toUserUpdate: self.handleEvent)
    }
    
    func handleEvent(event: MXEvent?) {
        print("MATRIXUSER\tListener fired for user [\(self.id)]")
        self.objectWillChange.send()
        
        if let mxevent = event {
            print("MATRIXUSER\tHandling a Matrix event for \(self.id)")
            print("MATRIXUSER\tEvent type is: \(mxevent.isUserProfileChange() ? "Profile change" : "Other" )")
            print("MATRIXUSER\tRoom = \(mxevent.roomId)")
            print("MATRIXUSER\tType = \(mxevent.type)")
        }
    }
    
    func refreshProfile(completion: @escaping (MXResponse<MatrixUser>) -> Void) {
        self.matrix.legacy.refreshUser(userId: self.id) { response in
            if response.isSuccess {
                self.objectWillChange.send()
            }
            completion(response)
        }
    }
    
    @Published var displayName: String?
    
    func setDisplayName(newName: String) async throws {
        guard displayName != newName
        else {
            return
        }
        try await matrix.setMyDisplayName(newName)
        await MainActor.run {
            self.displayName = newName
        }
    }
    
    var statusMsg: String? {
        mxuser.statusMsg
    }
    
    var avatarURL: String? {
        mxuser.avatarUrl
    }
    
    var initials: String {
        if let name = displayName {
            let toks = name.split(separator: " ")
            var letters = ""
            letters = toks.reduce(letters) { (curr,str) in
                guard let letter = str.first else {
                    return curr
                }
                return curr + String(letter)
            }
            return letters
        }
        // We don't have a display name
        // Return the first real (non "@") letter of the userid instead
        return String(self.id.prefix(2).suffix(1).capitalized)
    }
    
    @Published var avatarImage: UIImage?

    func _fetchAvatar(from url: String) {
        print("USER\tFetching avatar image for \(self.id)")
        guard let cached_image = self.matrix.legacy.getCachedImage(mxURI: url) else {
            print("USER\tNo avatar image for \(self.id) in cache.  Downloading now...")
            //self.queue.async {
                //if !self.downloadingAvatar {
                    //self.downloadingAvatar = true
                    self.matrix.legacy.downloadImage(mxURI: url) { image in
                        print("USER\tDownloaded avatar image for \(self.id)")
                        DispatchQueue.main.async {
                            //self.objectWillChange.send()
                            self.avatarImage = image
                        }
                        //self.downloadingAvatar = false

                        // Now, next time when SwiftUI comes back to re-render,
                        // it will find the image in the cache.
                        // No need to do anything else right now.
                    }
                //}
            //}
            // Do Nothing for now.  Just wait for the image to download.
            return
        }
        print("USER\tUsing cached image for \(self.id)")
        self.avatarImage = cached_image
        return
    }

    func updateAvatar() {
        //guard let url = self.mxuser.avatarUrl else {
        //    print("USER\tCouldn't find an avatar URL for user \(self.displayName ?? self.id)")
            matrix.legacy.getAvatarUrl(userId: self.id) { response in
                guard case let .success(newUrl) = response else {
                    print("USER\tCouldn't get avatar URL from Matrix for \(self.id)")
                    return
                }
                print("USER\tGot an avatar URL from Matrix for \(self.id)")
                self._fetchAvatar(from: newUrl.absoluteString)
            }
            return
        //}
        //print("USER\tAlready have the avatar URL for user \(self.id)")
        //self._fetchAvatar(from: url)
    }
    
    func setAvatarImage(image: UIImage, completion: @escaping (MXResponse<URL>) -> Void) {
        if matrix.creds.userId == userId {
            matrix.legacy.setAvatarImage(image: image) { response in
                if response.isSuccess {
                    print("USER\tSuccessfully set avatar image")
                    self.avatarImage = image
                    self.objectWillChange.send()
                }
                completion(response)
            }
        }
        else {
            let msg = "Error: Can't set the avatar image for any user but yourself!"
            print(msg)
            completion(.failure(KSError(message: msg)))
        }
    }
    
    
    var rooms: [MatrixRoom] {
        self.matrix.legacy.getRooms(ownedBy: self)
    }
    
    var devices: [MatrixCryptoDevice] {
        self.matrix.legacy.getDevices(userId: self.id)
    }
    
    /*
    var threepids: [String] {
        //
    }
    */
    
    func verify() {
        self.matrix.legacy.verify(userId: self.id) { response in
            if response.isSuccess {
                self.objectWillChange.send()
            }
        }
    }
    
    func unverify() {
        /*
        // FIXME %#^@&ing Matrix doesn't support un-verifying users.  Bastards.
        self.matrix.unverify(userId: self.id) { response in
            if response.isSuccess {
                self.objectWillChange.send()
            }
        }
        */
    }
    
    var isVerified: Bool {
        let trustLevel = matrix.legacy.getTrustLevel(userId: self.id)
        return trustLevel.isVerified
    }
    
    var isCrossSigningVerified: Bool {
        let trustLevel = matrix.legacy.getTrustLevel(userId: self.id)
        return trustLevel.isCrossSigningVerified
    }
    
    var isLocallyVerified: Bool {
        let trustLevel = matrix.legacy.getTrustLevel(userId: self.id)
        return trustLevel.isLocallyVerified
    }
}

extension MatrixUser: Hashable {
    // For Equatable
    static func == (lhs: MatrixUser, rhs: MatrixUser) -> Bool {
        return lhs.id == rhs.id
    }
    
    // For Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
