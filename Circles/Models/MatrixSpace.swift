//
//  MatrixSpace.swift
//  Circles
//
//  Created by Charles Wright on 6/21/22.
//

import Foundation

class MatrixSpace: ObservableObject {
    var api: MatrixAPI
    var roomId: RoomId
    var name: String?
    @Published var children: Set<RoomId>
    
    init(roomId: RoomId, api: MatrixAPI) {
        self.api = api
        self.roomId = roomId
        self.name = nil
        self.children = []
    }
    
    private func load() async throws {
        let newChildren = try await api.getSpaceChildren(roomId)
        await MainActor.run {
            self.children = Set(newChildren)
        }
        // FIXME: Fetch the name too???
    }
    
    class func factory(roomId: RoomId, api: MatrixAPI) async throws -> MatrixSpace {
        var space = MatrixSpace(roomId: roomId, api: api)
        try await space.load()
        return space
    }
    
    func addChild(with childRoomId: RoomId) async throws {
        try await api.addSpaceChild(childRoomId, to: self.roomId)
        await MainActor.run {
            self.children = self.children.union(Set([childRoomId]))
        }
    }
    
    func removeChild(with childRoomId: RoomId) async throws {
        try await api.removeSpaceChild(childRoomId, from: self.roomId)
        await MainActor.run {
            self.children = self.children.subtracting(Set([childRoomId]))
        }
    }
    
}
