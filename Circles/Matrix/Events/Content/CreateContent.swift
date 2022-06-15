//
//  CreateContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct CreateContent: Codable {
    let creator: String
    let federate: Bool
    
    struct PreviousRoom: Codable {
        let eventId: String
        let roomId: RoomId
    }
    let predecessor: PreviousRoom
    
    let roomVersion: String
    let type: String?
}
