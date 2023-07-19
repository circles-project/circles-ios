//
//  CircleSpace.swift
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
    
    var following: [UserId] {
        self.rooms.compactMap {
            $0.creator
        }.filter {
            $0 != self.session.creds.userId
        }
    }
    
    var timestamp: Date? {
        self.rooms.compactMap { room -> Date? in
            room.timeline.values.last?.timestamp
        }
        .max()
    }
    
    var canPaginateRooms: Bool {
        // We can paginate the circle if it contains even a single room that can be paginated
        for room in rooms {
            if room.canPaginate {
                return true
            }
        }
        // If we're still here, then every room said 'No'
        return false
    }
    
    func paginateRooms(limit: UInt? = nil) async throws {
        
        // Given two rooms, which of them has the earliest first message?
        func compare(r0: Matrix.Room, r1: Matrix.Room) throws -> Bool {
            guard let m1 = r1.timeline.values.first
            else {
                // We don't have *any* messages for room r1!
                return true
            }
            guard let m0 = r0.timeline.values.first
            else {
                return false
            }
            
            return m0.timestamp < m1.timestamp
        }
        
        // Not every room can necessarily paginate.  We're only concerned with the ones that can.
        let candidateRooms = self.rooms.filter({$0.canPaginate})
        
        // Find the room whose earliest message has the latest timestamp
        // ie, the room that needs to be paginated next so that we can scroll backwards through the collated timeline
        guard let lastFirstRoom = try candidateRooms.max(by: compare)
        else {
            // Looks like we can't paginate after all
            return
        }
    
        // ok now we know which room needs to be paginated next -- go ahead and load it
        try await lastFirstRoom.paginate(limit: limit)
    }
}
