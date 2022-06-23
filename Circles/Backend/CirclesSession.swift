//
//  CirclesSession.swift
//  Circles
//
//  Created by Charles Wright on 6/21/22.
//

import Foundation
import XCTest

class CirclesSession: ObservableObject {
    
    var matrix: MatrixSession
    private var rootSpaceRoomId: RoomId
    private var circlesSpaceRoomId: RoomId
    private var groupsSpaceRoomId: RoomId
    private var galleriesSpaceRoomId: RoomId
    
    @Published var circles: Set<SocialCircle>
    @Published var groups: Set<SocialGroup>
    @Published var galleries: Set<PhotoGallery>
    
    init(matrix: MatrixSession, root: RoomId, circles: RoomId, groups: RoomId, galleries: RoomId) {
        self.matrix = matrix
        
        self.circles = []
        self.groups = []
        self.galleries = []
        
        self.rootSpaceRoomId = root
        self.circlesSpaceRoomId = circles
        self.groupsSpaceRoomId = groups
        self.galleriesSpaceRoomId = galleries
    }
    
    class func factory(matrix: MatrixSession) async throws -> CirclesSession {
        let EVENT_TYPE_CIRCLES_CONFIG = "org.futo.circles.config"
        struct CirclesConfig: Codable {
            var root: RoomId
            var circles: RoomId
            var groups: RoomId
            var galleries: RoomId
        }
        let config = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG, of: CirclesConfig.self)

        return CirclesSession(matrix: matrix, root: config.root, circles: config.circles, groups: config.groups, galleries: config.galleries)
    }
    

    
    private func loadCircles() async throws {
        
        let circleIds = try await matrix.getSpaceChildren(circlesSpaceRoomId)
        var newCircles = [SocialCircle]()
        for circleId in circleIds {
            let newCircle = try await SocialCircle.factory(roomId: circleId, session: self)
            newCircles.append(newCircle)
        }
        let newSet = Set(newCircles) // We can't use a var in the MainActor code below.  Has to be a let constant.
        await MainActor.run {
            self.circles = self.circles.union(newSet)
        }
    }
    
    private func loadGroups() async throws {
        let groupIds = try await matrix.getSpaceChildren(groupsSpaceRoomId)
        var newGroups = [SocialGroup]()
        for groupId in groupIds {
            if let room = try await matrix.getRoom(roomId: groupId) {
                let newGroup = SocialGroup(room: room, session: self)
                newGroups.append(newGroup)
            }
        }
        let newSet = Set(newGroups)
        await MainActor.run {
            self.groups = self.groups.union(newSet)
        }
    }
    
    private func loadGalleries() async throws {
        let galleryIds = try await matrix.getSpaceChildren(galleriesSpaceRoomId)
        var newGalleries = [PhotoGallery]()
        for galleryId in galleryIds {
            if let room = try await matrix.getRoom(roomId: galleryId) {
                let newGallery = PhotoGallery(room: room, session: self)
                newGalleries.append(newGallery)
            }
        }
        let newSet = Set(newGalleries)
        await MainActor.run {
            self.galleries = self.galleries.union(newSet)
        }
    }
    
    func leaveGroup(groupId: RoomId, reason: String? = nil) async throws {
        try await matrix.leave(roomId: groupId, reason: reason)
        
        await MainActor.run {
            self.groups = self.groups.filter {
                $0.groupId != groupId
            }
        }
    }
    
    func leaveGallery(galleryId: RoomId, reason: String? = nil) async throws {
        try await matrix.leave(roomId: galleryId, reason: reason)
        
        await MainActor.run {
            self.galleries = self.galleries.filter {
                $0.galleryId != galleryId
            }
        }
    }
}
