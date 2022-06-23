//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  KSStream.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import Foundation
import UIKit
import MatrixSDK

class SocialStream: ObservableObject, Identifiable {
    var id: String
    var space: MatrixSpace
    // FIXME Compute the room list dynamically.
    //       Save lots of heartache chasing down sychronization bugs
    //var rooms: [MatrixRoom] // FIXME Make this a Set
    //var rooms: Set<MatrixRoom>
    //var store: KSStore
    //var graph: SocialGraph
    //var matrix: MatrixInterface
    var session: CirclesSession
    
    
    init(space: MatrixSpace, session: CirclesSession) {
        self.space = space
        self.id = "\(space.roomId)"
        self.session = session
    }
    
    var name: String {
        space.name
    }
    
    /*
    init(for user: MatrixUser) {
        self.name = user.id
        self.tag = user.id
        self.matrix = user.matrix
        
        let userRooms = user.rooms
        for room in userRooms {
            if !room.tags.contains(self.tag) {
                room.addTag(tag: self.tag) { _ in }
            }
        }
    }
    */
    
    
    // For displaying a consistent chronological view of the
    // Stream, we need to keep track of the "last first" message
    // and the channel that contains it.  ie the channel whose
    // first downloaded message was sent later than all of the
    // other channels' first downloaded messages.
    var lastFirstRoom: MatrixRoom? {
        self.rooms
            .filter({$0.canPaginate()})
            .max(by: {
                let t0 = $0.first?.timestamp ?? Date(timeIntervalSince1970: TimeInterval(0.0))
                let t1 = $1.first?.timestamp ?? Date(timeIntervalSince1970: TimeInterval(0.0))
                return t0 < t1
            }) ?? nil
    }
    
    var lastFirstMessage: MatrixMessage? {
        self.lastFirstRoom?.first ?? nil
    }
    
    var timestamp: Date? {
        let lastUpdatedRoom = self.rooms.max {
            $0.timestamp < $1.timestamp
        }
        return lastUpdatedRoom?.timestamp
    }
    
    var latestMessage: MatrixMessage? {
        let lastUpdatedRoom = self.rooms.max {
            $0.timestamp < $1.timestamp
        }
        return lastUpdatedRoom?.last
    }
    
    var canPaginate: Bool {
        guard let room = self.lastFirstRoom else {
            return false
        }
        return room.canPaginate()
    }
    
    func paginate(count: UInt = 25, completion: @escaping (MXResponse<Void>)->Void) {
        guard let room = self.lastFirstRoom else {
            let msg = "KSDEBUG Can't paginate -- No last first room"
            let err = KSError(message: msg)
            print(msg)
            completion(.failure(err))
            return
        }
        
        //self.objectWillChange.send()
        
        print("KSDEBUG Paginating room \(room.displayName ?? room.id)")
        room.paginate(count: count) { response in
            if response.isSuccess {
                self.objectWillChange.send()
            }
            completion(response)
        }
    }
    
    /* // Switching this to an explicit getter function so
       // that we can have an optional timestamp in the request
    var messages: [MatrixMessage] {
        var messages: [MatrixMessage] = []
        
        messages = self.rooms.reduce(messages) { (curr,room) in
            curr + room.messages
        }
        
        // FIXME Should we also sort by timestamp?
        return messages
    }
    */
    
    func getMessages(since date: Date? = nil) -> [MatrixMessage] {
        var messages: [MatrixMessage] = []
        
        print("KSDEBUG Getting messages for Stream [\(self.name)]")
        
        // By default, show everything since our last first message
        let startDate = date ?? self.lastFirstMessage?.timestamp
        print("KSDEBUG Start date is [\(startDate)]")
        //let startDate: Date? = nil
        
        messages = self.rooms.reduce(messages) { (curr,room) in
            let chunk = room.getMessages(since: startDate)
            print("KSDEBUG\tFound \(chunk.count) messages for room [\(room.displayName ?? room.id)]")
            print("KSDEBUG\t(Room has \(room.messages.count) total messages)")
            return curr + chunk
        }
        
        return messages.sorted(by: {$0.timestamp > $1.timestamp})
    }

    func getTopLevelMessages(since date: Date? = nil) -> [MatrixMessage] {
        self.getMessages(since: date)
            .filter( {$0.relatesToId == nil} )
    }
    
    var rooms: [MatrixRoom] {
        space.children.compactMap {
            session.matrix.legacy.getRoom(roomId: "\($0)")
        }
    }
    
    var people: Set<MatrixUser> {
        let users: Set<MatrixUser> = []
        return rooms.reduce(users) { (curr,room) in
            curr.union(Set(room.owners))
        }
    }
    
    var invertedIndex: [MatrixUser: [MatrixRoom]] {
        var invIndex: [MatrixUser: [MatrixRoom]] = [:]
        
        print("PEOPLE Building inverted index for Stream [\(name)] (\(rooms.count) rooms)")
        for room in rooms {
            let users = room.owners
            for user in users {
                var userRooms = invIndex[user] ?? []
                userRooms.append(room)
                invIndex[user] = userRooms
            }
        }
        
        return invIndex
    }
    
    var images: [UIImage] {
        rooms.compactMap { room in
            room.avatarImage
        }
    }
    
}

extension SocialStream: Hashable {
    static func == (lhs: SocialStream, rhs: SocialStream) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
