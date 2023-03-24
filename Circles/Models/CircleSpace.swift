//
//  CircleRoom.swift
//  Circles
//
//  Created by Charles Wright on 3/23/23.
//

import Foundation
import Matrix

class CircleSpace: ContainerRoom<Matrix.Room> {
    
    var wall: Matrix.Room? {
        self.rooms.first(where: {$0.creator == self.session.creds.userId})
    }
    
    var followers: [UserId] {
        self.wall?.joinedMembers ?? []
    }
    
    var timestamp: Date? {
        self.rooms.compactMap { room -> Date? in
            room.timeline.values.last?.timestamp
        }
        .max()
    }
}
