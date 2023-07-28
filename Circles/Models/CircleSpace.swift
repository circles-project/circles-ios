//
//  CircleSpace.swift
//  Circles
//
//  Created by Charles Wright on 3/23/23.
//

import Foundation
import os
import Matrix

class CircleSpace: ContainerRoom<Matrix.Room> {
    
    var wall: Matrix.Room? {
        self.rooms.first(where: {$0.creator == self.session.creds.userId})
    }
    
    var followers: [UserId] {
        self.wall?.joinedMembers.filter( {
            $0 != self.session.creds.userId // Not a "Yes, sir", not a follower...  Have a seat in the foyer.  Take a number.
        }) ?? []
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
    
    var lastFirstRoom: Matrix.Room? {
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
        guard let answer = try? candidateRooms.max(by: compare)
        else {
            // Looks like we can't paginate after all
            return nil
        }
        
        return answer
    }
    
    func paginateRooms(limit: UInt? = nil) async throws {
        // ok now we know which room needs to be paginated next -- go ahead and load it
        try await lastFirstRoom?.paginate(limit: limit)
    }
    
    func paginateEmptyTimelines(limit: UInt? = nil) async throws {
        for room in rooms {
            let timelineMessages = room.timeline.values.filter({ [M_ROOM_MESSAGE, M_ROOM_ENCRYPTED].contains($0.type) })
            if timelineMessages.isEmpty {
                self.logger.debug("Paginating room \(room.name ?? "??") (\(room.roomId.stringValue))")
                try await room.paginate(limit: limit)
            }
        }
    }
    
    func getCollatedTimeline(since: Date = .init(timeIntervalSince1970: 0.0), filter: (Matrix.Message) -> Bool) -> [Matrix.Message] {
        let logger = os.Logger(subsystem: "circles", category: "timeline")
        logger.debug("Getting collated timeline for circle \(self.name ?? "??") (\(self.roomId.stringValue))")
        let unsorted: [Matrix.Message] = self.rooms.reduce([], { (curr,room) in
            curr + room.messages.filter(filter).filter {
                $0.timestamp >= since
            }
        })
        return unsorted.sorted(by: { (m0,m1) -> Bool in
            m0.timestamp < m1.timestamp
        })
    }
}
