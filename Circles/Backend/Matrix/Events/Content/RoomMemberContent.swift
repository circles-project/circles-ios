//
//  RoomMemberContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct RoomMemberContent: Codable {
    let avatarUrl: String?
    let displayname: String?
    let isDirect: Bool?
    let joinAuthorizedUsersViaServer: String?
    enum Membership: String, Codable {
        case invite
        case join
        case knock
        case leave
        case ban
    }
    let membership: Membership
    let reason: String?
    struct Invite: Codable {
        let displayName: String
    }
    let thirdPartyInvite: Invite?
}
