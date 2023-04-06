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
    
    enum State {
        case profile
        case circles(String)
        case allDone
    }
    @Published var state: State
    
    init(creds: Matrix.Credentials, store: CirclesStore) async throws {
        self.creds = creds
        self.store = store
        //self.client = try Matrix.Client(creds: creds)
        self.client = try await Matrix.Session(creds: creds, startSyncing: false)
        self.state = .profile
    }
    
    func setupProfile(name: String, avatar: UIImage) async throws {
        try await client.setMyDisplayName(name)
        try await client.setMyAvatarImage(avatar)
        await MainActor.run {
            self.state = .circles(name)
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
        let myPeople = try await client.createSpace(name: "My People")
        
        print("- Adding Space child relationships")
        
        try await client.addSpaceChild(myCircles, to: topLevelSpace)
        try await client.addSpaceChild(myGroups, to: topLevelSpace)
        try await client.addSpaceChild(myGalleries, to: topLevelSpace)
        try await client.addSpaceChild(myPeople, to: topLevelSpace)
        
        print("- Adding tag to top-level space")
        try await client.addTag(roomId: topLevelSpace, tag: ROOM_TAG_CIRCLES_SPACE_ROOT)
        
        print("- Uploading Circles config to account data")
        let config = CirclesConfigContent(root: topLevelSpace, circles: myCircles, groups: myGroups, galleries: myGalleries, people: myPeople)
        try await client.putAccountData(config, for: EVENT_TYPE_CIRCLES_CONFIG)
        
        for circle in circles {
            print("- Creating circle [\(circle.name)]")
            let circleRoomId = try await client.createSpace(name: circle.name)
            let wallRoomId = try await client.createRoom(name: circle.name, type: ROOM_TYPE_CIRCLE)
            if let avatar = circle.avatar {
                try await client.setAvatarImage(roomId: wallRoomId, image: avatar)
            }
            try await client.addSpaceChild(wallRoomId, to: circleRoomId)
            try await client.addSpaceChild(circleRoomId, to: myCircles)
        }
        
        await MainActor.run {
            self.state = .allDone
        }
    }
    
}
