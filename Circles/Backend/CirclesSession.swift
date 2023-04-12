//
//  CirclesSession.swift
//  Circles
//
//  Created by Charles Wright on 6/21/22.
//

import Foundation
import Matrix
import os

#if os(macOS)
import AppKit
#else
import UIKit
#endif


class CirclesSession: ObservableObject {
    var logger: os.Logger
    
    
    var matrix: Matrix.Session
    
    // We don't actually use the "Circles" root space room very much
    // Mostly it's just there to hide our stuff from cluttering up the rooms list in other clients
    // But here we hold on to its roomid in case we need it for anything
    // IDEA: We could store any Circles-specific configuration info in our account data in this room
    var rootRoomId: RoomId
    
    //typealias CircleRoom = ContainerRoom<Matrix.Room> // Each circle is a space, where we know we are joined in every child room
    //typealias PersonRoom = Matrix.SpaceRoom // Each person's profile room is a space, where we may or may not be members of the child rooms
    
    var circles: ContainerRoom<CircleSpace>     // Our top-level circles space contains the spaces for each of our circles
    var groups: ContainerRoom<GroupRoom>        // Top-level groups space contains the individual rooms for each of our groups
    var galleries: ContainerRoom<GalleryRoom>   // Top-level galleries space contains the individual rooms for each of our galleries
    var people: ContainerRoom<PersonRoom>       // Top-level people space contains the space rooms for each of our contacts
    
    init(matrix: Matrix.Session) async throws {
        self.logger = Logger(subsystem: "Circles", category: "Session")
        self.matrix = matrix
        
        let startTS = Date()
        
        logger.debug("Loading config from Matrix")
        let configStart = Date()
        let config = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG, of: CirclesConfigContent.self)
        let configEnd = Date()
        let configTime = configEnd.timeIntervalSince(configStart)
        logger.debug("\(configTime) sec to load config from the server")

        logger.debug("Loading Matrix spaces")
        
        
        let groupsStart = Date()
        guard let groups = try await matrix.getRoom(roomId: config.groups, as: ContainerRoom<GroupRoom>.self)
        else {
            logger.error("Failed to load Groups space")
            throw CirclesError("Failed to load Groups space")
        }
        let groupsEnd = Date()
        let groupsTime = groupsEnd.timeIntervalSince(groupsStart)
        logger.debug("\(groupsTime) sec to load Groups space")
        
        
        let galleriesStart = Date()
        guard let galleries = try await matrix.getRoom(roomId: config.galleries, as: ContainerRoom<GalleryRoom>.self)
        else {
            logger.error("Failed to load Galleries space")
            throw CirclesError("Failed to load Galleries space")
        }
        let galleriesEnd = Date()
        let galleriesTime = galleriesEnd.timeIntervalSince(galleriesStart)
        logger.debug("\(galleriesTime) sec to load Galleries space")
        
        
        let circlesStart = Date()
        guard let circles = try await matrix.getRoom(roomId: config.circles, as: ContainerRoom<CircleSpace>.self)
        else {
            logger.error("Failed to load Circles space")
            throw CirclesError("Failed to load Circles space")
        }
        let circlesEnd = Date()
        let circlesTime = circlesEnd.timeIntervalSince(circlesStart)
        logger.debug("\(circlesTime) sec to load Circles space")
        
        
        let peopleStart = Date()
        guard let people = try await matrix.getRoom(roomId: config.people, as: ContainerRoom<PersonRoom>.self)
        else {
            logger.error("Failed to load People space")
            throw CirclesError("Failed to load People space")
        }
        let peopleEnd = Date()
        let peopleTime = peopleEnd.timeIntervalSince(peopleStart)
        logger.debug("\(peopleTime) sec to load People space")
        
        self.rootRoomId = config.root
        
        self.groups = groups
        self.galleries = galleries
        self.circles = circles
        self.people = people
        
        let endTS = Date()
        
        let totalTime = endTS.timeIntervalSince(startTS)
        logger.debug("\(totalTime) sec to initialize Circles Session")
        
        try await matrix.startBackgroundSync()
        
        /*
        // FIXME: CRAZY DEBUGGING
        Task {
            while true {
                if let (roomId, room) = self.matrix.rooms.randomElement() {
                    let imageName = ["diamond.fill", "circle.fill", "square.fill", "seal.fill", "shield.fill"].randomElement()!
                    let image = UIImage(systemName: imageName)
                    await MainActor.run {
                        print("Randomizing avatar for room \(roomId.opaqueId) / \(room.roomId.opaqueId) to be \(imageName)")
                        room.avatar = image
                    }
                }
                try await Task.sleep(for: .seconds(2))
            }
        }
        */
    }

    
    func close() async throws {
        try await matrix.close()
    }
}
