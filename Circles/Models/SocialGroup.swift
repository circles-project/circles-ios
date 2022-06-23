//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//  Copyright 2022 FUTO Holdings, Inc
//
//  SocialGroup.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import Foundation
import MatrixSDK

//typealias SocialGroup = MatrixRoom

class SocialGroup: ObservableObject, Identifiable {
    var room: MatrixRoom
    var session: CirclesSession
    
    init(room: MatrixRoom, session: CirclesSession) {
        self.room = room
        self.session = session
    }
    
    var id: String {
        self.room.id
    }
    
    var groupId: RoomId {
        room.roomId
    }
    
    func leave(reason: String? = nil) async throws
    {
        try await session.leaveGroup(groupId: groupId, reason: reason)
    }
    
    var name: String? {
        self.room.displayName
    }
}

extension SocialGroup: Hashable {
    static func == (lhs: SocialGroup, rhs: SocialGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/*
class KSChannel: MatrixRoom {
    
}
*/
