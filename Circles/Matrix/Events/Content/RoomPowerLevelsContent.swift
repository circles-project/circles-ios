//
//  RoomPowerLevelsContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct RoomPowerLevelsContent: Codable {
    var invite: Int
    var kick: Int
    var ban: Int
    
    var events: [String: Int]
    var eventsDefault: Int

    var notifications: [String: Int]
    
    var redact: Int
    
    var stateDefault: Int

    var users: [String: Int]
    var usersDefault: Int
}
