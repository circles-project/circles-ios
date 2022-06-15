//
//  MinimalEvent.swift
//  
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation

// The bare minimum implementation of the MatrixEvent protocol
// Used for decoding other event types
// Also used in the /sync response for AccountData, Presence, etc.
struct MinimalEvent: MatrixEvent {
    let type: EventType
    let content: Codable
    
    enum CodingKeys: String, CodingKey {
        case type
        case content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(EventType.self, forKey: .type)
        self.content = try decodeEventContent(of: self.type, from: decoder)
    }

}

