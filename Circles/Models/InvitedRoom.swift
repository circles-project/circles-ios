//
//  InvitedRoom.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 12/21/20.
//
//  InvitedRoom is like MatrixRoom, but much more limited.
//  It only supports the basic functionality needed to display an invitation.
//  We use this so that we avoid creating a MatrixRoom for a room where we
//  don't yet have the full complete information.  It seems that, when we do
//  that, the Room doesn't ever quite work right once we join.  So instead,
//  now we create an InvitedRoom for use before we have the full access, and
//  once we join, we can create a fresh MatrixRoom with full functionality,
//  and it shouldn't be messed up by the original incomplete state.

import Foundation
import MatrixSDK

class InvitedRoom: ObservableObject, Identifiable {
    var matrix: MatrixInterface
    private var mxroom: MXRoom
    var id: String
    var isPending = true
    
    init(from mxroom: MXRoom, on matrix: MatrixInterface) {
        self.mxroom = mxroom
        self.matrix = matrix
        self.id = mxroom.roomId
    }
    
    // Copied from MatrixRoom
    var displayName: String? {
        mxroom.summary.displayname
    }
    
    // Copied from MatrixRoom
    var avatarURL: String? {
        mxroom.summary.avatar
    }
    
    // Copied from MatrixRoom
    var avatarImage: UIImage? {
        guard let url = mxroom.summary.avatar else { return nil }
        guard let cached_image = self.matrix.getCachedImage(mxURI: url) else {
            matrix.downloadImage(mxURI: url) { new_image in
                self.objectWillChange.send()
                print("Fetched avatar image for \(self.id)")
            }
            return nil
        }
        print("Using cached image for \(self.id)")
        return cached_image
    }
    
    // Copied from MatrixRoom
    func whoInvitedMe() -> String? {
        let me = self.matrix.whoAmI()
        guard let enumerator = mxroom.enumeratorForStoredMessagesWithType(in: ["m.room.member"]) else {
            return nil
        }
        var batch: [MXEvent]? = nil
        var inviteEvent: MXEvent? = nil
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
    
    // Adapted from MatrixRoom
    func join(tags: [String] = [],  completion: @escaping (_ response: MXResponse<MatrixRoom>) -> Void = {_ in }) {
        if mxroom.summary.membership == .join {
            return
        }
        
        mxroom.join { response1 in
            switch(response1) {
            case .failure(let error):
                print("Failed to join room \(self.id): \(error)")
                completion(.failure(error))
                
            case .success:
                self.isPending = false
                self.objectWillChange.send()
                
                let dgroup = DispatchGroup()
                var failures: KSError? = nil
                
                // Now that we have access to the full Room state,
                // we can instantiate a full MatrixRoom
                guard let room = self.matrix.getRoom(roomId: self.mxroom.roomId) else {
                    completion(.failure(KSError(message: "Couldn't init Matrix Room")))
                    return
                }
                
                for tag in tags {
                    dgroup.enter()
                    room.addTag(tag: tag) { response2 in
                        if response2.isFailure {
                            let msg = "Failed to set tag [\(tag)]"
                            print(msg)
                            failures = failures ?? KSError(message: msg)
                        }
                        dgroup.leave()
                    }
                }
                
                dgroup.notify(queue: .main) {
                    if let fail = failures {
                        completion(.failure(fail))
                    }
                    else {
                        completion(.success(room))
                    }
                }
            }
        }
    }
    
}
