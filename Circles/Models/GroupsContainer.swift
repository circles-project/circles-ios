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
    var matrix: MatrixInterface
    @Published var groups: [SocialGroup] = []
    
    init(_ interface: MatrixInterface) {
        self.matrix = interface
        
        // Because we can't initialize any SocialGroup instances using our current 'self' as the GroupsContainer...
        // Why doing it in this function is better, I'm not sure...
        self.reload()
    }
    
    func reload() {
        if !self.groups.isEmpty {
            self.groups.removeAll()
        }
        let newGroups = self.matrix.getRooms(for: ROOM_TAG_GROUP)
            .map { room in
                SocialGroup(from: room, on: self)
            }
        self.groups.append(contentsOf: newGroups)
    }
    
    /*
    var groups: [MatrixRoom] {
        matrix.getRooms(for: ROOM_TAG_GROUP)
    }
    */

    func add(roomId: String) {
        guard let room = self.matrix.getRoom(roomId: roomId) else {
            print("GROUPS\tFailed to add a group for roomId \(roomId)")
            return
        }
        let group = SocialGroup(from: room, on: self)
        self.groups.append(group)
    }
        
    func create(name: String, completion: @escaping (MXResponse<SocialGroup>) -> Void)
    {
        self.matrix.createRoom(name: name,
                               type: ROOM_TYPE_GROUP,
                               tag: ROOM_TAG_GROUP,
                               insecure: false
        ) { response in
            switch(response) {
            case .failure(let err):
                let msg = "Failed to create Room for new Group [\(name)]"
                print("CREATEGROUP\t\(msg)")
                completion(.failure(KSError(message: msg)))
            case .success(let roomId):
                print("CREATEGROUP\tSuccess!  Created new group [\(name)]")
                if let room = self.matrix.getRoom(roomId: roomId) {
                    room.setRoomType(type: ROOM_TYPE_GROUP) { response2 in
                        if response2.isSuccess {
                            self.objectWillChange.send()
                            let newGroup = SocialGroup(from: room, on: self)
                            self.groups.insert(newGroup, at: 0)
                            completion(.success(newGroup))
                        }
                        else {
                            // No reason to leave the room hanging around
                            self.matrix.leaveRoom(roomId: roomId, completion: {_ in })

                            let msg = "Failed to tag new Room as a Group"
                            completion(.failure(KSError(message: msg)))
                        }
                    }
                }
                else {
                    let msg = "Couldn't create MatrixRoom from mxroom"
                    completion(.failure(KSError(message: msg)))
                }
            }
        }
    }
    
    func leave(group: SocialGroup, completion: @escaping (MXResponse<String>)->Void)
    {
        self.matrix.leaveRoom(roomId: group.room.id) { success in
            if success {
                self.groups.removeAll(where: { candidate in
                    candidate.id == group.id
                })
                completion(.success(group.id))
            }
            else {
                let msg = "Failed to leave group \(group.id)"
                completion(.failure(KSError(message: msg)))
            }
        }
    }
}
