//
//  SetupSession.swift
//  Circles
//
//  Created by Charles Wright on 6/14/22.
//

import Foundation
import UIKit

class SetupSession: ObservableObject {
    var creds: MatrixCredentials
    var store: CirclesStore
    var api: MatrixAPI
    var displayName: String
    
    enum State {
        case profile
        case circles
        case allDone
    }
    @Published var state: State
    
    init(creds: MatrixCredentials, store: CirclesStore, displayName: String) throws {
        self.creds = creds
        self.store = store
        self.api = try MatrixAPI(creds: creds)
        self.displayName = displayName
        self.state = .profile
    }
    
    func setupProfile(name: String, avatar: UIImage) async throws {
        try await api.setDisplayName(name)
        try await api.setAvatarImage(avatar)
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
        let topLevelSpace = try await api.createSpace(name: "Circles")
        let myCircles = try await api.createSpace(name: "My Circles")
        let myGroups = try await api.createSpace(name: "My Groups")
        let myGalleries = try await api.createSpace(name: "My Photo Galleries")
        
        print("- Adding Space child relationships")
        
        try await api.spaceAddChild(myCircles, to: topLevelSpace)
        try await api.spaceAddChild(myGroups, to: topLevelSpace)
        try await api.spaceAddChild(myGalleries, to: topLevelSpace)
        
        print("- Adding tag to top-level space")
        try await api.roomAddTag(roomId: topLevelSpace, tag: ROOM_TAG_CIRCLES_SPACE_ROOT)
        
        for circle in circles {
            print("Creating circle [\(circle.name)]")
            let circleRoom = try await api.createSpace(name: circle.name)
            let wallRoom = try await api.createRoom(name: circle.name, type: ROOM_TYPE_CIRCLE)
            try await api.spaceAddChild(wallRoom, to: circleRoom)
            try await api.spaceAddChild(circleRoom, to: myCircles)
        }
        
        await MainActor.run {
            self.state = .allDone
        }
    }
    
}
