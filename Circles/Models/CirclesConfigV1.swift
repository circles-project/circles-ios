//
//  CirclesConfig.swift
//  Circles
//
//  Created by Charles Wright on 3/30/23.
//

import Foundation
import Matrix

let EVENT_TYPE_CIRCLES_CONFIG_V1 = "org.futo.circles.config"

struct CirclesConfigContentV1: Codable {
    var root: RoomId
    var circles: RoomId
    var groups: RoomId
    var galleries: RoomId
    var people: RoomId
    var profile: RoomId // aka Shared Circles
}
