//
//  RoomTagContent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct RoomTagContent: Codable {
    struct Tag: Codable {
        let order: Float
    }
    var tags: [String: Tag]
}
