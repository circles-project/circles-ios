//
//  StrippedStateEvent.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

extension Matrix {

    // https://spec.matrix.org/v1.2/client-server-api/#stripped-state

    struct StrippedStateEvent: MatrixEvent {
        let sender: UserId
        let stateKey: String
        let type: EventType
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
            self.type = try container.decode(EventType.self, forKey: .type)
            
            self.content = try decodeEventContent(of: self.type, from: decoder)
        }
    }

}
