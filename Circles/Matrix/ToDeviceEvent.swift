//
//  ToDeviceEvent.swift
//  
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation

    
// https://spec.matrix.org/v1.2/client-server-api/#extensions-to-sync
struct ToDeviceEvent: MatrixEvent {
    var content: Codable
    var type: MatrixEventType
    var sender: UserId
    
    enum CodingKeys: String, CodingKey {
        case content
        case type
        case sender
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sender = try container.decode(UserId.self, forKey: .sender)
        self.type = try container.decode(MatrixEventType.self, forKey: .type)
        //let minimal = try MinimalEvent(from: decoder)
        //self.content = minimal.content
        self.content = try Matrix.decodeEventContent(of: self.type, from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sender, forKey: .sender)
        try container.encode(type, forKey: .type)
        try Matrix.encodeEventContent(content: content, of: type, to: encoder)
    }
}

