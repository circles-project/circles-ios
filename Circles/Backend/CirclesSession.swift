//
//  CirclesSession.swift
//  Circles
//
//  Created by Charles Wright on 6/21/22.
//

import Foundation
import Matrix

class CirclesSession: ObservableObject {
    
    var matrix: Matrix.Session
    
    // We don't actually use the "Circles" root space room very much
    // Mostly it's just there to hide our stuff from cluttering up the rooms list in other clients
    // But here we hold on to its roomid in case we need it for anything
    // IDEA: We could store any Circles-specific configuration info in our account data in this room
    var rootRoomId: RoomId
    
    //typealias CircleRoom = ContainerRoom<Matrix.Room> // Each circle is a space, where we know we are joined in every child room
    //typealias PersonRoom = Matrix.SpaceRoom // Each person's profile room is a space, where we may or may not be members of the child rooms
    
    var circles: ContainerRoom<CircleSpace>     // Our top-level circles space contains the spaces for each of our circles
    var groups: ContainerRoom<GroupRoom>     // Top-level groups space contains the individual rooms for each of our groups
    var galleries: ContainerRoom<GalleryRoom>  // Top-level galleries space contains the individual rooms for each of our galleries
    var people: ContainerRoom<PersonRoom>      // Top-level people space contains the space rooms for each of our contacts
    
    init(matrix: Matrix.Session) async throws {
        self.matrix = matrix
        
        let config = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG, of: CirclesConfigContent.self)

        guard let groups = try await matrix.getRoom(roomId: config.groups, as: ContainerRoom<GroupRoom>.self),
              let galleries = try await matrix.getRoom(roomId: config.galleries, as: ContainerRoom<GalleryRoom>.self),
              let circles = try await matrix.getRoom(roomId: config.circles, as: ContainerRoom<CircleSpace>.self),
              let people = try await matrix.getRoom(roomId: config.people, as: ContainerRoom<PersonRoom>.self)
        else {
            throw CirclesError("Failed to initialize Circles space hierarchy")
        }
        
        self.rootRoomId = config.root
        
        self.groups = groups
        self.galleries = galleries
        self.circles = circles
        self.people = people
    }

    
    func close() async throws {
        try await matrix.close()
    }
}
