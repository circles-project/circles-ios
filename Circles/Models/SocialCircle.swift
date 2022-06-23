//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  SocialCircle.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/14/20.
//

import Foundation
import MatrixSDK

class SocialCircle: ObservableObject, Identifiable {

    var space: MatrixSpace
    var session: CirclesSession
    var wall: MatrixRoom?
    
    var id: String {
        space.roomId.description
    }
    
    var name: String? {
        space.name
    }
    
    var stream: SocialStream
    
    init(space: MatrixSpace, wall: MatrixRoom?, session: CirclesSession) {
        self.session = session
        self.space = space
        self.wall = wall
        self.stream = SocialStream(space: space, session: session)
    }
    
    class func create(roomId: RoomId, session: CirclesSession) async throws -> SocialCircle {
        let space = try await MatrixSpace.create(roomId: roomId, api: session.matrix)
        
        // FIXME: Find the wall room
        let roomIds = space.children
        var rooms = [MatrixRoom]()
        for roomId in roomIds {
            if let room = try await session.matrix.getRoom(roomId: roomId) {
                rooms.append(room)
            }
        }
        let wall = rooms.first {
            $0.creatorId == session.matrix.creds.userId
        }

        let circle = SocialCircle(space: space, wall: wall, session: session)
        return circle
    }
    
    var followers: [MatrixUser] {
        var members = self.wall?.joinedMembers ?? []
        members.removeAll { user in
            user.userId == session.matrix.creds.userId
        }
        return members
    }
    
    func follow(room: MatrixRoom) async throws {
        guard let roomId = RoomId(room.id)
        else {
            throw CirclesError("Invalid room id")
        }
        try await space.addChild(with: roomId)
    }
    
    func unfollow(room: MatrixRoom) async throws {
        guard let roomId = RoomId(room.id)
        else {
            throw CirclesError("Invalid room id")
        }
        try await space.removeChild(with: roomId)
    }
}

extension SocialCircle: Hashable {
    static func == (lhs: SocialCircle, rhs: SocialCircle) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
