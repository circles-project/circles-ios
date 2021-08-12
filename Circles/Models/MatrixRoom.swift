//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MatrixRoom.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/28/20.
//

// swiftlint:disable identifier_name

import Foundation
import MatrixSDK

class MatrixRoom: ObservableObject, Identifiable, Equatable, Hashable {
    private let mxroom: MXRoom
    let id: String
    let matrix: MatrixInterface
    private var localEchoEvent: MXEvent?
    private var backwardTimeline: MXEventTimeline?

    var first: MatrixMessage?
    var last: MatrixMessage?

    var queue: DispatchQueue
    var downloadingAvatar: Bool = false
    private var cachedAvatarImage: UIImage?
    
    // This local info works together with the MXSession's ignored users list,
    // which is stored in the Matrix account_data.
    // Having a local ignore list lets us block out messages from users who
    // weren't ignored when the message came in, but have since been ignored.
    private var ignoredSenders: Set<String> = []

    init(from mxroom: MXRoom, on matrix: MatrixInterface) {
        self.mxroom = mxroom
        self.id = mxroom.roomId
        self.matrix = matrix
        self.queue = DispatchQueue(label: self.id, qos: .background)

        self.initTimeline()
        self.refresh()
    }

    func initPowerLevels() {
        mxroom.state { state in
            if let allPLs = state?.powerLevels {
                self.objectWillChange.send()
                self.cachedPowerLevels = allPLs
            }
        }
    }


    func _eventHandler(event: MXEvent, direction: MXTimelineDirection, state: MXRoomState) {

        print("TIMELINE --------")
        print("TIMELINE Handling new event with id [\(event.eventId ?? "???")]")
        if event.eventType == .roomEncrypted {
            print("TIMELINE Event [\(event.eventId ?? "???")] is encrypted.  Hopefully we'll see it again.")
            return
        } else if event.eventType == .roomMessage {
            print("TIMELINE Event [\(event.eventId ?? "???")] is a room message.  Processing...")
        } else if event.eventType == .reaction {
            // FIXME Look at MXAggregations.h for the SDK's way of supporting reactions
            // * There's a `listenToReactionCountUpdateInRoom()` function that we can use to keep track of the reactions
            // * There's a `aggregatedReactionsOnEvent()` function for getting all the reactions for an event
            // So how in the world do we get an instance of this thing???
            // --> It's matrix.session.aggregations :)
            print("TIMELINE Event [\(event.eventId ?? "???")] is a reaction.  Ignoring for now...")
        }
        print("TIMELINE --------")
        
        // Hide messages from people on our ignore list
        if self.ignoredSenders.contains(event.sender) {
            return
        }

        let msg = MatrixMessage(from: event, in: self)
        self.objectWillChange.send()
        self.messages.insert(msg)

        if self.first == nil || msg.timestamp < self.first!.timestamp {
            self.first = msg
        }

        if self.last == nil || msg.timestamp > self.last!.timestamp {
            self.last = msg
        }

        if self.localEchoEvent?.eventId == event.eventId {
            // Aha, here's the "real" version of our local echo guy.  We only need this to exist in one place.
            self.localEchoEvent = nil
        }
    }

    func initTimeline() {
        self.backwardTimeline = MXEventTimeline(room: mxroom, andInitialEventId: nil)
        self.backwardTimeline?.resetPagination()

        //let eventTypes: [MXEventType] = [.roomMessage, .roomEncrypted]
        let eventTypes: [MXEventType] = [.roomMessage]
        _ = self.backwardTimeline?.listenToEvents(eventTypes, self._eventHandler)

        self.mxroom.liveTimeline() { maybeTimeline in
            guard let timeline = maybeTimeline else {
                return
            }

            _ = timeline.listenToEvents(eventTypes, self._eventHandler)
        }
    }

    func refresh() {
        self.updateOwners()
        self.updateMembers()
        // self.loadMessages(max: 25)
        self.paginate() { _ in }
    }

    var type: String? {
        self.mxroom.summary.roomTypeString
    }

    // FIXME Make this one settable as well as gettable
    //       The set() just makes the API call
    var displayName: String? {
        mxroom.summary.displayname
    }

    func setDisplayName(_ name: String, completion: @escaping (MXResponse<Void>) -> Void) {
        mxroom.setName(name) { response in
            switch response {
            case .failure(let error):
                print("Failed to set display name for room \(self.id): \(error)")
            case .success:
                self.objectWillChange.send()
            }
            completion(response)
        }
    }

    // FIXME Make this one settable as well as gettable
    //       The set() just makes the API call
    var topic: String? {
        mxroom.summary.topic
    }

    // FIXME Make this one settable as well as gettable
    //       The set() just makes the API call
    var avatarURL: String? {
        mxroom.summary.avatar
    }

    // FIXME Make this one settable as well as gettable
    //       The set() just makes the API call
    var avatarImage: UIImage? {
        // Do we already have the image in our little one-off cache?
        if let img = self.cachedAvatarImage {
            return img
        }
        // Image isn't cached.  Do we have a URL?
        guard let url = mxroom.summary.avatar else {
            // No URL.  We're SOL.
            return nil
        }
        // So we don't have the image, but we know where to find it.
        // Let's go get it.
        // Maybe it's in the disk cache?
        guard let cached_image = self.matrix.getCachedImage(mxURI: url) else {
            // Nope, not in the disk cache.
            // Gotta go out to the homeserver and fetch it
            print("ROOM\tCached avatar image was nil for \(self.id)")
            self.queue.sync(flags: .barrier) {
                if !self.downloadingAvatar {
                    self.downloadingAvatar = true
                    self.matrix.downloadImage(mxURI: url) { downloadedImage in
                        self.cachedAvatarImage = downloadedImage
                        DispatchQueue.main.async {
                            self.objectWillChange.send()
                        }
                        print("ROOM\tFetched avatar image for \(self.id)")
                        self.downloadingAvatar = false
                    }
                } else {
                    print("ROOM\tAvatar is already being downloaded; Doing nothing")
                }
            }
            return nil
        }
        // Yay it was in the disk cache
        print("ROOM\tUsing cached image for \(self.id)")
        return cached_image
    }

    func setAvatarURL(url: URL, completion: @escaping (MXResponse<Void>) -> Void = {_ in }) {
        self.mxroom.setAvatar(url: url) { response in
            if response.isSuccess {
                // Invalidate our old cache of the image
                self.cachedAvatarImage = nil
                // Tell SwiftUI it's time to redraw
                self.objectWillChange.send()
            }
            completion(response)
        }
    }

    func setAvatarImage(image: UIImage, completion: @escaping (MXResponse<Void>) -> Void = { _ in }) {
        print("Setting avatar image")
        matrix.uploadImage(image: image) { response in
            switch response {
            case .failure(let error):
                print("Error: Failed to upload image for new avatar.  Error: \(error)")
                completion(.failure(error))

            case .progress(let progress):
                print("Progress: New avatar upload is \(100 * progress.fractionCompleted)% complete")

            case .success(let url):
                self.setAvatarURL(url: url, completion: completion)
            }
        }
    }

    func enableEncryption(completion: @escaping (MXResponse<Void>)->Void) {
        self.mxroom
            .enableEncryption(withAlgorithm: "m.megolm.v1.aes-sha2",
                              completion: completion)
    }

    var membership: MXMembership {
        return mxroom.summary.membership
    }

    // FIXME Why not just
    //      @Published var owners: [MatrixUser]
    // and then whenever the list changes, Combine will automagically
    // send out an update, and we don't have to mess with it ourselves.
    // Then we could have SwiftUI View's that observe *just* the owners
    // list, and not the whole room.
    private var cachedOwnerUserIds: Set<String> = []
    var owners: [MatrixUser] {
        cachedOwnerUserIds.compactMap { userId in
            self.matrix.getUser(userId: userId)
        }
    }

    private var cachedPowerLevels: MXRoomPowerLevels?
    private var powerLevels: MXRoomPowerLevels? {
        if let PLs = cachedPowerLevels {
            //print("POWERLEVELS\tUsing cached power levels")
            return PLs
        }

        print("POWERLEVELS\tNo cached power levels, asking the Matrix server ...")
        mxroom.state { state in
            if let allPLs = state?.powerLevels {
                self.objectWillChange.send()
                self.cachedPowerLevels = allPLs
            }
        }
        return nil
    }

    var userPowerLevels: [String: Int] {
        guard let PLs = self.powerLevels else {
            print("POWERLEVELS\tNo power levels available for users")
            return [:]
        }

        guard let userPLs = PLs.users else {
            print("POWERLEVELS\tNo user power levels")
            return [:]
        }

        let upl = userPLs as? [String: Int] ?? [String: Int]()
        /*
        print("POWERLEVELS\tHave \(upl.count) user power levels")
        for (u, p) in upl {
            print("POWERLEVELS\t\(u)\t\(p)")
        }
        */
        return upl
    }

    func getPowerLevel(userId: String) -> Int {
        if let power = userPowerLevels[userId] {
            return power
        }

        if let PLs = powerLevels {
            return PLs.usersDefault
        }

        return 0
    }

    func setPowerLevel(userId: String, power: Int, completion handler: @escaping (MXResponse<Void>) -> Void) {
        mxroom.setPowerLevel(ofUser: userId, powerLevel: power) { response in
            if response.isSuccess {
                self.objectWillChange.send()
                // Also update our local cache
                self.cachedPowerLevels?.users[userId] = power
            }

            handler(response)
        }
    }

    func amIaModerator() -> Bool {
        guard let power = self.userPowerLevels[matrix.whoAmI()] else {
            return false
        }

        return power >= 50
    }

    func asyncOwners(completion: @escaping (MXResponse<[MatrixUser]>) -> Void) {
        mxroom.state { state in
            guard let PLs = state?.powerLevels?.users else {
                let msg = "Couldn't find power levels"
                completion(.failure(KSError(message: msg)))
                return
            }

            var owners: [MatrixUser] = []
            for (u, l) in PLs {
                // swiftlint:disable:next force_cast
                let userId = u as! String
                // swiftlint:disable:next force_cast
                let level = l as! Int
                if level >= 100 {
                    if let user = self.matrix.getUser(userId: userId) {
                        owners.append(user)
                    }
                }
            }
            completion(.success(owners))
        }
    }

    func updateOwners() {
        // Find the owners (powerlevel 100) of the room
        var newOwnerIds: Set<String> = []
        mxroom.state { state in
            guard let allPLs = state?.powerLevels else {
                print("POWERLEVELS\tCouldn't find ANY power levels for room \(self.id)")
                return
            }
            self.cachedPowerLevels = allPLs // Save this data for later

            guard let userPowerLevels = allPLs.users else {
                print("POWELEVELS\tCouldn't find user power levels for room \(self.id)")
                return
            }
            for (u, l) in userPowerLevels {
                // swiftlint:disable:next force_cast
                let userId = u as! String
                // swiftlint:disable:next force_cast
                let level = l as! Int
                print("POWERLEVELS\tFound user [\(userId)] with power level [\(level)] ")
                if level >= 100 {
                    self.objectWillChange.send()
                    newOwnerIds.insert(userId)
                }
            }
            // Did we find any changes?
            if newOwnerIds.symmetricDifference(self.cachedOwnerUserIds).count > 0 {
                self.objectWillChange.send()
                self.cachedOwnerUserIds = newOwnerIds
            }
        }
    }

    private var cachedMemberUserIds: [String] = []

    // var roomLocalAvatarUrls: [String: String] = [:]
    // var roomLocalDisplayNames: [String: String] = [:]

    private var mxMembers: MXRoomMembers?

    func updateMembers() {
        mxroom.members { response in
            switch response {
            case .failure(let error):
                print("Failed to get members for room \(self.displayName ?? self.id) -- \(error)")
            case .success(let maybeMembers):
                // FIXME What if we already had a list of members, and now we get a nil?
                self.mxMembers = maybeMembers
                self.objectWillChange.send()
            }
        }
    }

    func asyncMembers(completion: @escaping (MXResponse<[MatrixUser]>) -> Void) {

        mxroom.members { response in
            switch response {
            case .failure(let err):
                let msg = "Failed to get members: \(err)"
                print(msg)
                completion(.failure(KSError(message: msg)))
            case .success(let maybeMxMembers):
                if let members = maybeMxMembers {
                    self.mxMembers = members
                    self.objectWillChange.send()

                    let users = members.joinedMembers.compactMap { mxroommember in
                        self.matrix.getUser(userId: mxroommember.userId)
                    }
                    completion(.success(users))
                }
            } 
        }
    }

    // FIXME Create a single function to use for all these
    var joinedMembers: [MatrixUser] {
        guard let mxm = self.mxMembers else {
            updateMembers()
            return []
        }
        let joinedList: [MXRoomMember] = mxm.joinedMembers
        return joinedList.compactMap { mxroommember in
            matrix.getUser(userId: mxroommember.userId)
        }
    }

    // FIXME Create a single function to use for all these
    var invitedMembers: [MatrixUser] {
        guard let mxm = self.mxMembers else {
            return []
        }
        let memberList: [MXRoomMember] = mxm.members(with: __MXMembershipInvite)
        return memberList.compactMap { mxroommember in
            matrix.getUser(userId: mxroommember.userId)
        }
    }

    // FIXME Create a single function to use for all these
    var leftMembers: [MatrixUser] {
        guard let mxm = self.mxMembers else {
            return []
        }
        let memberList: [MXRoomMember] = mxm.members(with: __MXMembershipLeave)
        return memberList.compactMap { mxroommember in
            matrix.getUser(userId: mxroommember.userId)
        }
    }

    // FIXME Create a single function to use for all these
    var bannedMembers: [MatrixUser] {
        guard let mxm = self.mxMembers else {
            return []
        }
        let memberList: [MXRoomMember] = mxm.members(with: __MXMembershipBan)
        return memberList.compactMap { mxroommember in
            matrix.getUser(userId: mxroommember.userId)
        }
    }
    
    var membersCount: UInt {
        mxroom.summary.membersCount.joined
    }

    var timestamp: Date {
        let seconds = mxroom.summary.lastMessage.originServerTs / 1000
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }
    
    // FIXME Make messages @Published, so we don't have to deal with
    //       sending the update manually when it changes
    // var messages: [MatrixMessage] = []
    //
    // 2020-11-20 Making the message store a Set instead of Array
    //            Now we need to handle messages coming in from
    //            potentially multiple different directions, eg.
    //            the room's timeline event handler(s).
    //            Just to be sure we never get duplicates, we're
    //            going with the Set for internal purposes.
    //            This also lets us get away from caring about
    //            keeping the thing sorted internally, and it
    //            should be more efficient to test whether or not
    //            a given message is in our collection.
    var messages: Set<MatrixMessage> = []
    
    func canPaginate() -> Bool {
        backwardTimeline?.canPaginate(.backwards) ?? false
    }

    // Request more messages from the server (and/or the MXStore)
    func paginate(count: UInt = 25, completion: @escaping (MXResponse<Void>)->Void) {
        guard let timeline = self.backwardTimeline else {
            let msg = "Error: No timeline for room [\(self.displayName ?? self.id)]"
            let err = KSError(message: msg)
            print(msg)
            completion(.failure(err))
            return
        }

        if !timeline.canPaginate(.backwards) {
            let msg = "Error: Can't paginate our timeline for room [\(self.displayName ?? self.id)]"
            let err = KSError(message: msg)
            print(msg)
            completion(.failure(err))
            return
        }
        
        timeline.paginate(count, direction: .backwards, onlyFromStore: false) { response in
            // When we get this call, the timeline will have been populated in the MXSession/MXStore
            switch response {
            case .failure(let error):
                print("Pagination request failed: \(error)")
            case .success:
                self.objectWillChange.send()
            }
            completion(response)
        }
    }

    func getMessages(since date: Date? = nil) -> [MatrixMessage] {
        if let cutoff = date {
            var result = self.messages
                .filter({ $0.timestamp > cutoff })
                .filter({ !self.ignoredSenders.contains($0.sender) })
                .sorted(by: {$0.timestamp > $1.timestamp})
            print("Found \(result.count) messages since \(date) in room [\(self.displayName ?? self.id)]")
            return result
        } else {
            // return Array(self.messages)
            return self.messages
                .filter({ !self.ignoredSenders.contains($0.sender) })
                .sorted(by: {$0.timestamp > $1.timestamp})
        }
    }

    func getTopLevelMessages(since date: Date? = nil) -> [MatrixMessage] {
        self.getMessages(since: date)
            .filter( {$0.relatesToId == nil} )
    }

    func getReplies(to eventId: String) -> [MatrixMessage] {
        return self.getMessages().filter { (msg) in
            switch msg.content {
            case .text(let content):
                return content.relates_to?.in_reply_to?.event_id == eventId
            case .notice(let content):
                return content.relates_to?.in_reply_to?.event_id == eventId
            default:
                return false
            }
        }
    }
    
    var localEchoMessage: MatrixMessage? {
        guard let mxevent = self.localEchoEvent else {
            return nil
        }
        return MatrixMessage(from: mxevent, in: self)
    }

    var membershipEvents: [MXEvent] {
        if let enumerator = mxroom.enumeratorForStoredMessagesWithType(in: ["m.room.member"]) {
            return enumerator.nextEventsBatch(100) ?? []
        }
        return []
    }

    func whoInvitedMe() -> String? {
        let me = self.matrix.whoAmI()
        guard let enumerator = mxroom.enumeratorForStoredMessagesWithType(in: ["m.room.member"]) else {
            return nil
        }
        var batch: [MXEvent]?
        var inviteEvent: MXEvent?
        repeat {
            batch = enumerator.nextEventsBatch(100)
            inviteEvent = batch?.last {
                $0.type == kMXEventTypeStringRoomMember && $0.stateKey == me
            }
            if let event = inviteEvent {
                return event.sender
            }
        } while inviteEvent == nil && batch != nil

        return nil
    }

    func invite(userId: String, completion: @escaping (MXResponse<Void>) -> Void = { _ in }) {
        print("ROOM\tInviting user [\(userId)]")
        mxroom.invite(.userId(userId)) { response in
            switch response {
            case .failure(let err):
                print("ROOM\tFailed to invite \(userId) -- \(err)")
            case .success:
                print("ROOM\tSuccessfully invited \(userId)")
            }
            completion(response)
        }
    }
    
    func kick(userId: String, reason: String, completion: @escaping (MXResponse<String>) -> Void = { _ in }) {
        print("Kicking user \(userId) from room \(self.displayName ?? self.id)")
        mxroom.kickUser(userId, reason: reason) { response in
            switch response {
            case .failure(let err):
                let msg = "Failed to kick user [\(userId)]"
                print(msg)
                completion(.failure(KSError(message: msg)))
            case .success:
                print("Successfully kicked user \(userId)")
                self.updateMembers()
                self.objectWillChange.send()
                completion(.success(userId))
            }
        }
    }

    func ban(userId: String, reason: String, completion: @escaping (MXResponse<String>) -> Void = { _ in }) {
        mxroom.banUser(userId, reason: reason) { response in
            switch response {
            case .failure(let err):
                completion(.failure(KSError(message: "Failed to ban user [\(userId)]")))
            case .success:
                self.updateMembers()
                self.objectWillChange.send()
                completion(.success(userId))
            }
        }
    }
    
    func setTopic(topic: String, completion: @escaping (MXResponse<Void>) -> Void) {
        self.mxroom.setTopic(topic) { response in
            switch response {
            case .failure(let error):
                print("Failed to set topic: \(error)")
            case .success:
                self.objectWillChange.send()
                // print("Yay success changing topic")
            }
            completion(response)
        }
    }

    var isEncrypted: Bool {
        mxroom.summary.isEncrypted
    }

    func postText(text: String, completion: @escaping (MXResponse<String?>) -> Void) {
        self.localEchoEvent = nil
        self.mxroom.sendTextMessage(text, localEcho: &self.localEchoEvent) { response in
            switch response {
            case .failure(let error):
                print("POST Failed to send text message: \(error)")
            case .success(let eventIdFromServer):
                self.objectWillChange.send()

                // At this point, we should have our "real" eventId from the homeserver.
                // Let's go ahead and put the message into the collection.
                if let event = self.localEchoEvent {
                    let msg = MatrixMessage(from: event, in: self)
                    self.messages.insert(msg)
                    // IMPORTANT: We also must remove the local echo,
                    // or any Views that try to use it will get double-vision
                    self.localEchoEvent = nil
                }

            }
            completion(response)
        }
    }

    func postReply(to event: MXEvent, text: String, completion: @escaping (MXResponse<String?>) -> Void) {
        // FIXME This shit does some of the most awful butchering I've ever seen
        //       It copies the parent message right into the content!
        //       NOT what we want here, when we have a "real"er threaded(-ish) UI
        /*
        self.mxroom.sendReply(to: event,
                              textMessage: text,
                              formattedTextMessage: nil,
                              stringLocalizations: nil,
                              localEcho: &self.localEchoEvent,
                              completion: completion)
        */

        // Better version.  Hack it together ourselves with the lower-level function
        let inReplyTo: [String: String] = ["event_id": event.eventId]
        let relatesTo: [String: [String:String]] = ["m.in_reply_to": inReplyTo]
        var content: [String: Any] = [:]
        content["msgtype"] = kMXMessageTypeText
        content["body"] = text
        content["m.relates_to"] = relatesTo
        self.mxroom.sendMessage(withContent: content, localEcho: &self.localEchoEvent, completion: completion)
    }

    func postImage(image: UIImage, caption: String? = nil, completion: @escaping (MXResponse<String?>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.90) else {
            let msg = "Failed to compress image"
            print(msg)
            completion(.failure(KSError(message: msg)))
            return
        }

        let thumbnailSize = CGSize(width: CGFloat(640), height: CGFloat(640))
        guard let thumb = downscale_image(from: image, to: thumbnailSize) else {
            let msg = "Failed to create thumbnail"
            print(msg)
            completion(.failure(KSError(message: msg)))
            return
        }
        
        // Created these vars to track the actual image data that we're going to upload
        // It might be the original, or if that's too big, it might be the downsampled
        var uploadImage = image
        var uploadData = data

        // Don't try to upload more than 4 MB
        let MAX_DATA_SIZE = 4 << 20
        
        if data.count > MAX_DATA_SIZE {
            print("Need to resize...")
            let maxSize = CGSize(width: CGFloat(1024), height: CGFloat(768))
            guard let newImage = downscale_image(from: image, to: maxSize) else {
                let msg = "Failed to downscale image"
                print(msg)
                completion(.failure(KSError(message: msg)))
                return
            }
            guard let newData = newImage.jpegData(compressionQuality: 0.75) else {
                let msg = "Failed to compress downscaled image"
                print(msg)
                completion(.failure(KSError(message: msg)))
                return
            }
            uploadImage = newImage
            uploadData = newData
        }

        var blurhash: String?
        let tinyWidth: Int = BLURHASH_WIDTH * 16
        let tinyHeight: Int = Int(CGFloat(tinyWidth) * thumb.size.height / thumb.size.width)
        let tinySize = CGSize(width: tinyWidth, height: tinyHeight)
        print("SENDIMAGE\tTiny image is \(tinyWidth)x\(tinyHeight)")
        // BlurHash'ing the thumbnail was sloooooooow
        // Let's see what happens with a 4x smaller version
        if let tiny = downscale_image(from: thumb, to: tinySize) {
            let blurWidth: Int = BLURHASH_WIDTH
            let blurHeight: Int = Int( CGFloat(blurWidth) * CGFloat(tinyHeight) / CGFloat(tinyWidth))
            print("SENDIMAGE\tBlurHash will be \(blurWidth)x\(blurHeight)")
            blurhash = tiny.blurHash(numberOfComponents: (blurWidth,blurHeight))
        }

        print("SENDIMAGE\tAttempting to upload \(uploadData.count) data")
        self.mxroom.sendImage(
            data: uploadData,
            size: uploadImage.size,
            mimeType: "image/jpeg",
            thumbnail: thumb,
            blurhash: blurhash,
            caption: caption,
            localEcho: &self.localEchoEvent
        ) { response in
            switch response {
            case .failure(let error):
                print("SENDIMAGE\tFailed to send image: \(error)")
                completion(.failure(KSError(message: "Failed to send image")))
            case .success(let msg):
                print("SENDIMAGE\tUpload image success!  [\(msg ?? "(no response message)")]")
                self.objectWillChange.send()

                // At this point, we should have our "real" eventId from the homeserver.
                // Let's go ahead and put the message into the collection.
                if let event = self.localEchoEvent {
                    let msg = MatrixMessage(from: event, in: self)
                    self.messages.insert(msg)
                    // IMPORTANT: We also must remove the local echo,
                    // or any Views that try to use it will get double-vision
                    self.localEchoEvent = nil
                }
                completion(.success(msg))
            }
        }
    }
    
    var tags: [String] {
        guard let tags = mxroom.accountData.tags else {
            return []
        }
        // Not sure why we have to do this moronic dance,
        // when Swift should already know that the Key type is String.
        // Hmmm...  #ThisWillAllMakeSenseWhenIAmOlder
        return tags.keys.compactMap { tag in
            tag
        }
    }

    func addTag(tag: String, completion: @escaping (MXResponse<Void>) -> Void) {
        let order = String(format: "%1.2f", Double.random(in: 0 ..< 1))
        mxroom.addTag(tag, withOrder: order, completion: completion)
    }

    func removeTag(tag: String, completion handler: @escaping (MXResponse<Void>) -> Void) {
        mxroom.removeTag(tag) { response in
            switch response {
            case .failure(let error):
                let msg = "Failed to remove tag \"\(tag)\": \(error)"
                print(msg)
            case .success:
                print("Successfully set tag \"\(tag)\"!")
            }
            handler(response)
        }
    }

    func getRoomType(completion: @escaping (MXResponse<String>) -> Void) {
        // Do we have a room type from the creation event?
        if let creationType = self.type {
            completion(.success(creationType))
        }
        else {
            // This room must be older -- No room type in the creation event :(
            // Let's go spelunking through the room state and see if we can find a type
            mxroom.state { roomstate in
                let events: [MXEvent] = roomstate?.stateEvents(with: .custom(EVENT_TYPE_ROOMTYPE)) ?? []
                let maybeEvent = events
                    .sorted(by: {$0.originServerTs < $1.originServerTs})
                    .first
                guard let event = maybeEvent else {
                    let msg = "Couldn't find room type - No state events"
                    print(msg)
                    completion(.failure(KSError(message: msg)))
                    return
                }

                let maybeMyType = event.content["type"] as? String

                guard let roomtype = maybeMyType else {
                    let msg = "Room has no type"
                    print(msg)
                    completion(.failure(KSError(message: msg)))
                    return
                }

                // Yay we finally found it
                completion(.success(roomtype))
            }
        }
    }

    func setRoomType(type: String, completion: @escaping (MXResponse<String>) -> Void) {

        mxroom.sendStateEvent(
            .custom(EVENT_TYPE_ROOMTYPE),
            content: ["type": type],
            stateKey: ""
        ) { response in
            switch response {
            case .failure(let err):
                let msg = "Failed to set room type: \(err)"
                print(msg)
                completion(.failure(KSError(message: msg)))
            case .success:
                let name = self.mxroom.summary.displayname ?? self.mxroom.roomId ?? "???"
                print("Successfully set room \(name) type to \(type)")
                completion(.success(type))
            }
        }
    }

    func redact(message: MatrixMessage, reason: String?, completion: @escaping (MXResponse<Void>) -> Void) {
        mxroom.redactEvent(message.id, reason: reason) { response in
            if response.isSuccess {
                self.objectWillChange.send()
                self.messages.subtract([message])
            }
            completion(response)
        }
    }
    
    func report(message: MatrixMessage, severity: Int, reasons: [String], completion: @escaping (MXResponse<Void>) -> Void) {
        let reason = reasons.joined(separator: "|")
        mxroom.reportEvent(message.id,
                           score: severity,
                           reason: reason) { response in
            if response.isSuccess {
                self.objectWillChange.send()
                self.messages.subtract([message])
            }
            completion(response)
        }
    }
    
    func ignoreUser(_ userId: String) {
        self.matrix.ignoreUser(userId: userId) { response in
            if response.isSuccess {
                self.ignoredSenders.insert(userId)
                self.objectWillChange.send()
            }
        }
    }
    
    func unignoreUser(_ userId: String) {
        self.matrix.unIgnoreUser(userId: userId) { response in
            if response.isSuccess {
                self.ignoredSenders.subtract([userId])
                self.objectWillChange.send()
            }
        }
    }

    var cryptoAlgorithm: String {
        if isEncrypted {
            return matrix.getCryptoAlgorithm(roomId: self.id)
        } else {
            return "Plaintext"
        }
    }

    var inboundOlmSessions: [MXOlmInboundGroupSession] {
        matrix.getInboundGroupSessions()
            .filter { groupSession in
                groupSession.roomId == self.id
            }
    }

    var outboundOlmSessions: [MXOlmOutboundGroupSession] {
        matrix.getOutboundGroupSessions()
            .filter { groupSession in
                groupSession.roomId == self.id
            }
    }

    // For Equatable
    static func == (lhs: MatrixRoom, rhs: MatrixRoom) -> Bool {
        return lhs.id == rhs.id
    }

    // For Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
