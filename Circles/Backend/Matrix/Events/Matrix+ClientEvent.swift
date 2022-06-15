//
//  MatrixClientEvent.swift
//  
//
//  Created by Charles Wright on 5/17/22.
//

import Foundation

extension Matrix {

    struct ClientEvent: MatrixEvent {
        let content: Codable
        let eventId: String
        let originServerTS: UInt64
        let roomId: RoomId
        let sender: UserId
        let stateKey: String?
        let type: EventType
        
        struct UnsignedData: Codable {
            let age: Int
            let prevContent: Codable
            let redactedBecause: ClientEvent?
            let transactionId: String?
        }
        let unsigned: UnsignedData?
        
        enum CodingKeys: String, CodingKey {
            case content
            case eventId = "event_id"
            case originServerTS = "origin_server_ts"
            case roomId = "room_id"
            case sender
            case stateKey = "state_key"
            case type
            case unsigned
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.eventId = try container.decode(String.self, forKey: .eventId)
            self.originServerTS = try container.decode(UInt64.self, forKey: .originServerTS)
            self.roomId = try container.decode(RoomId.self, forKey: .roomId)
            self.sender = try container.decode(UserId.self, forKey: .sender)
            self.stateKey = try? container.decode(String.self, forKey: .stateKey)
            self.type = try container.decode(EventType.self, forKey: .type)
            self.unsigned = try? container.decode(UnsignedData.self, forKey: .unsigned)
            
            self.content = try decodeEventContent(of: self.type, from: decoder)
        }
    }

}
