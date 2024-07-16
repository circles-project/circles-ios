//
//  CirclesConfigV2.swift
//  Circles
//
//  Created by Charles Wright on 7/10/24.
//

import Foundation
import Matrix

let EVENT_TYPE_CIRCLES_CONFIG_V2 = "org.futo.circles.config.v2"

struct CirclesConfigContentV2: Codable {
    var root: RoomId
    var groups: RoomId
    var galleries: RoomId
    var people: RoomId
    var profile: RoomId // aka Shared Circles
    var timelines: RoomId
}
