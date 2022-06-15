//
//  JoinRuleContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct JoinRuleContent: Codable {
    struct AllowCondition: Codable {
        let roomId: RoomId
        enum AllowConditionType: String, Codable {
            case mRoomMembership = "m.room_membership"
        }
        let type: AllowConditionType
    }
    enum JoinRule: String, Codable {
        case public_ = "public"
        case knock
        case invite
        case private_ = "private"
        case restricted
    }
    
    let allow: [AllowCondition]
    let joinRule: JoinRule
}
