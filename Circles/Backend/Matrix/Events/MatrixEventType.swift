//
//  MatrixEventType.swift
//  
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation

enum MatrixEventType: String, Codable {
    case mRoomCanonicalAlias = "m.room.canonical_alias"
    case mRoomCreate = "m.room.create"
    case mRoomJoinRules = "m.room.join_rules"
    case mRoomMember = "m.room.member"
    case mRoomPowerLevels = "m.room.power_levels"
    case mRoomMessage = "m.room.message"
    case mRoomEncryption = "m.room.encryption"
    case mEncrypted = "m.encrypted"
    
    case mRoomName = "m.room.name"
    case mRoomAvatar = "m.room.avatar"
    case mRoomTopic = "m.room.topic"
    
    case mTag = "m.tag"
    // case mRoomPinnedEvents = "m.room.pinned_events" // https://spec.matrix.org/v1.2/client-server-api/#mroompinned_events
    
    // Add types for extensible events here
}
