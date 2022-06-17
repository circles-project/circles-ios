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
    
    enum State {
        case profile
        case circles
        case allDone
    }
    @Published var state: State
    
    init(creds: MatrixCredentials, store: CirclesStore) throws {
        self.creds = creds
        self.store = store
        self.api = try MatrixAPI(creds: creds)
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
        async let topLevelSpace = api.createSpace(name: "Circles")
        async let myCircles = api.createSpace(name: "My Circles")
        async let myGroups = api.createSpace(name: "My Groups")
        async let myGalleries = api.createSpace(name: "My Photo Galleries")
        
        try await api.spaceAddChild(myCircles, to: topLevelSpace)
        try await api.spaceAddChild(myGroups, to: topLevelSpace)
        try await api.spaceAddChild(myGalleries, to: topLevelSpace)
        
        try await api.roomAddTag(roomId: topLevelSpace, tag: ROOM_TAG_CIRCLES_SPACE_ROOT)
        
        for circle in circles {
            print("Creating circle [\(circle.name)]")
            async let circleRoom = api.createSpace(name: circle.name)
            async let wallRoom = api.createRoom(name: circle.name, type: ROOM_TYPE_CIRCLE)
            try await api.spaceAddChild(wallRoom, to: circleRoom)
            try await api.spaceAddChild(circleRoom, to: myCircles)
        }
        
        await MainActor.run {
            self.state = .allDone
        }
    }
    
}
