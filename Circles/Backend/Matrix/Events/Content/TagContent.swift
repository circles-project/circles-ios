//
//  TagContent.swift
//  
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation

struct TagContent: Codable {
    struct Tag: Codable {
        var order: Float
    }
    var tags: [String: Tag]
}
