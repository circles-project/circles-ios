//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupsContainer.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/25/21.
//

import Foundation
import MatrixSDK

class GroupsContainer: ObservableObject {
    var matrix: MatrixSession
    var space: RoomId
    @Published var groups: [SocialGroup]
    
    init(space: RoomId, matrix: MatrixSession) {
        self.space = space
        self.matrix = matrix
        self.groups = []
        
        _ = Task {
            await reload()
        }
    }
    
    func reload() async {
        do {
            let newRoomIds = try await self.matrix.getSpaceChildren(space)
            self.groups.removeAll()
            let newGroups = newRoomIds.compactMap { (roomId: RoomId) -> SocialGroup? in
                guard let room = matrix.legacy.getRoom(roomId: "\(roomId)") else { return nil }
                return SocialGroup(from: room, on: self)
            }
        

            await MainActor.run {
                self.groups.append(contentsOf: newGroups)
            }
        } catch {
            print("GROUPS\tReload failed")
        }
    }
    
    /*
    var groups: [MatrixRoom] {
        matrix.getRooms(for: ROOM_TAG_GROUP)
    }
    */

    func add(roomId: RoomId) async throws {
        guard let room = matrix.legacy.getRoom(roomId: "\(roomId)") else {
            let msg = "GROUPS\tFailed to add a group for roomId \(roomId)"
            print(msg)
            throw CirclesError(msg)
        }
        try await matrix.addSpaceChild(roomId, to: space)
        let group = SocialGroup(from: room, on: self)
        await MainActor.run {
            self.groups.append(group)
        }
    }
        
    func create(name: String) async throws -> SocialGroup
    {
        let roomId = try await matrix.createRoom(name: name, type: ROOM_TYPE_GROUP, encrypted: true)
        let stringRoomId = "\(roomId)"
        guard let room = matrix.legacy.getRoom(roomId: stringRoomId)
        else {
            let msg = "Couldn't create MatrixRoom"
            print("GROUPS\t\(msg)")
            throw CirclesError(msg)
        }
        let group = SocialGroup(from: room, on: self)
        groups.append(group)
        return group
    }
    
    func leave(group: SocialGroup, reason: String? = nil) async throws
    {
        try await matrix.leave(roomId: group.roomId!, reason: reason)
    }
}
