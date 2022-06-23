//
//  ClientEventWithoutRoomId.swift
//  
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation

// Used for the /sync API
// Normally this would be defined in-line in the only place where it's used,
// but since it's much bigger than most random data-transfer object types,
// this one gets its own file.
struct ClientEventWithoutRoomId: MatrixEvent {
    let eventId: String
    let originServerTS: UInt64
    //let roomId: String
    let sender: UserId
    let stateKey: String?
    let type: MatrixEventType
    let content: Codable

    struct UnsignedData: Codable {
        let age: Int
        //let prevContent: Codable
        struct FakeClientEvent: Codable {
            var eventId: String
        }
        let redactedBecause: FakeClientEvent?
        let transactionId: String?
    }
    let unsigned: UnsignedData?
    
    enum CodingKeys: String, CodingKey {
        case content
        case eventId = "event_id"
        case originServerTS = "origin_server_ts"
        //case roomId = "room_id"
        case sender
        case stateKey = "state_key"
        case type
        case unsigned
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.eventId = try container.decode(String.self, forKey: .eventId)
        self.originServerTS = try container.decode(UInt64.self, forKey: .originServerTS)
        //self.roomId = try container.decode(String.self, forKey: .roomId)
        self.sender = try container.decode(UserId.self, forKey: .sender)
        self.stateKey = try? container.decode(String.self, forKey: .stateKey)
        self.type = try container.decode(MatrixEventType.self, forKey: .type)
        self.unsigned = try? container.decode(UnsignedData.self, forKey: .unsigned)
         
        self.content = try Matrix.decodeEventContent(of: self.type, from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(originServerTS, forKey: .originServerTS)
        try container.encode(sender, forKey: .sender)
        try container.encode(stateKey, forKey: .stateKey)
        try container.encode(type, forKey: .type)
        try container.encode(unsigned, forKey: .unsigned)
        try Matrix.encodeEventContent(content: content, of: type, to: encoder)
    }
}
