//
//  StrippedStateEvent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

// https://spec.matrix.org/v1.2/client-server-api/#stripped-state

struct StrippedStateEvent: MatrixEvent {
    let sender: UserId
    let stateKey: String
    let type: MatrixEventType
    let content: Codable

    enum CodingKeys: String, CodingKey {
        case sender
        case stateKey = "state_key"
        case type
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sender = try container.decode(UserId.self, forKey: .sender)
        self.stateKey = try container.decode(String.self, forKey: .stateKey)
        self.type = try container.decode(MatrixEventType.self, forKey: .type)
        
        self.content = try Matrix.decodeEventContent(of: self.type, from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sender, forKey: .sender)
        try container.encode(stateKey, forKey: .stateKey)
        try container.encode(type, forKey: .type)
        try Matrix.encodeEventContent(content: content, of: type, to: encoder)
    }
}
