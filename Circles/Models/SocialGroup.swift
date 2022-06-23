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
    var container: GroupsContainer
    
    init(from room: MatrixRoom, on container: GroupsContainer) {
        self.room = room
        self.container = container
    }
    
    var id: String {
        self.room.id
    }
    
    var roomId: RoomId? {
        room.roomId
    }
    
    func leave() async throws
    {
        try await self.container.leave(group: self)
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
