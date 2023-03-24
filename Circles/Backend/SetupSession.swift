//
//  SetupSession.swift
//  Circles
//
//  Created by Charles Wright on 6/14/22.
//

import Foundation
import UIKit

import Matrix

class SetupSession: ObservableObject {
    var creds: Matrix.Credentials
    var store: CirclesStore
    var client: Matrix.Client
    var displayName: String
    
    enum State {
        case profile
        case circles
        case allDone
    }
    @Published var state: State
    
    init(creds: Matrix.Credentials, store: CirclesStore, displayName: String) throws {
        self.creds = creds
        self.store = store
        self.client = try Matrix.Client(creds: creds)
        self.displayName = displayName
        self.state = .profile
    }
    
    func setupProfile(name: String, avatar: UIImage) async throws {
        try await client.setMyDisplayName(name)
        try await client.setMyAvatarImage(avatar)
        await MainActor.run {
            self.state = .circles
        }
    }
    
    struct CircleInfo {
        var name: String
        var avatar: UIImage?
    }
    
    func setupCircles(_ circles: [CircleInfo]) async throws {
        print("Creating Spaces hierarchy for Circles rooms")
        print("- Creating Space rooms")
        let topLevelSpace = try await client.createSpace(name: "Circles")
        let myCircles = try await client.createSpace(name: "My Circles")
        let myGroups = try await client.createSpace(name: "My Groups")
        let myGalleries = try await client.createSpace(name: "My Photo Galleries")
        
        print("- Adding Space child relationships")
        
        try await client.addSpaceChild(myCircles, to: topLevelSpace)
        try await client.addSpaceChild(myGroups, to: topLevelSpace)
        try await client.addSpaceChild(myGalleries, to: topLevelSpace)
        
        print("- Adding tag to top-level space")
        try await client.addTag(roomId: topLevelSpace, tag: ROOM_TAG_CIRCLES_SPACE_ROOT)
        
        for circle in circles {
            print("Creating circle [\(circle.name)]")
            let circleRoom = try await client.createSpace(name: circle.name)
            let wallRoom = try await client.createRoom(name: circle.name, type: ROOM_TYPE_CIRCLE)
            try await client.addSpaceChild(wallRoom, to: circleRoom)
            try await client.addSpaceChild(circleRoom, to: myCircles)
        }
        
        await MainActor.run {
            self.state = .allDone
        }
    }
    
}
