//
//  ContainerRoom.swift
//  Circles
//
//  Created by Charles Wright on 3/22/23.
//

import Foundation
import Matrix

class ContainerRoom<T: Matrix.Room>: Matrix.Room {
    public var rooms: [T]
    
    public required init(roomId: RoomId, session: Matrix.Session, initialState: [ClientEventWithoutRoomId], initialTimeline: [ClientEventWithoutRoomId] = []) throws {
        self.rooms = []
        try super.init(roomId: roomId, session: session, initialState: initialState, initialTimeline: initialTimeline)
        
        // Now let's look to see what (if any) child rooms we have
        
        if let dict = self.state[M_SPACE_CHILD] {
            let _ = Task {
                var tmpRooms = [T]()
                for (stateKey, event) in dict {
                    guard let childRoomId = RoomId(stateKey),
                          let content = event.content as? SpaceChildContent,
                          content.via?.first != nil
                    else {
                        continue
                    }
                    let stateEvents = try await self.session.getRoomStateEvents(roomId: roomId)
                    let room = try T(roomId: childRoomId, session: session, initialState: stateEvents, initialTimeline: [])
                    tmpRooms.append(room)
                }
                let newRooms = tmpRooms
                await MainActor.run {
                    self.rooms = newRooms
                }
            }
        }
    }
    
    // Add a Room object to our rooms list whenever we get a new space child
    public override func updateState(from event: ClientEventWithoutRoomId) async {
        // First do all the normal stuff to update our local room state
        await super.updateState(from: event)
        
        // Then check to see whether this event is one that we need to handle
        if event.type == M_SPACE_CHILD {
            // Make sure it's a valid space child event
            guard let stateKey = event.stateKey,
                  let content = event.content as? SpaceChildContent,
                  let childRoomId = RoomId(stateKey)
            else {
                return
            }
            
            // OK, are we adding or removing a space child room?
            if content.via?.first == nil {
                // We're removing an old child room from the space
                
                await MainActor.run {
                    self.rooms.removeAll(where: { $0.roomId == childRoomId })
                }
                return

            } else {
                // We're adding a new child room to the space
                
                guard let stateEvents = try? await self.session.getRoomStateEvents(roomId: roomId),
                      let room = try? T(roomId: roomId, session: self.session, initialState: stateEvents)
                else {
                    return
                }
                await MainActor.run {
                    self.rooms.append(room)
                }
            }
        }
    }
    
    public func leaveChildRoom(_ childRoomId: RoomId) async throws {
        try await self.session.removeSpaceChild(childRoomId, from: self.roomId)
        try await self.session.leave(roomId: childRoomId)
    }
    
    public func removeChildRoom(_ childRoomId: RoomId) async throws {
        try await self.session.removeSpaceChild(childRoomId, from: self.roomId)
        // NOTE: We don't have to do anything to the `rooms` object here.
        //       If everything works as it should, Matrix will give us the
        //       m.space.child event on our next sync, and then we will
        //       automatically create the Room object and add it to our list.
    }
    
    public func addChildRoom(_ childRoomId: RoomId) async throws {
        try await self.session.addSpaceChild(childRoomId, to: self.roomId)
        // NOTE: We don't have to do anything to the `rooms` object here.
        //       If everything works as it should, Matrix will give us the
        //       m.space.child event on our next sync, and then we will
        //       automatically create the Room object and add it to our list.
    }
    
    public func createChildRoom(name: String,
                                type: String?,
                                encrypted: Bool,
                                avatar: Matrix.NativeImage?
    ) async throws -> RoomId {
        let childRoomId = try await self.session.createRoom(name: name, type: type, encrypted: encrypted)
        try await self.addChildRoom(childRoomId)
        if let image = avatar {
            try await self.session.setAvatarImage(roomId: childRoomId, image: image)
        }
        return childRoomId
    }
}
