//
//  RoomId.swift
//  
//
//  Created by Charles Wright on 5/18/22.
//

import Foundation

struct RoomId: LosslessStringConvertible, Codable, Equatable, Hashable {
    let opaqueId: String
    let domain: String
    
    private static func validate(_ roomId: String) -> Bool {
        let toks = roomId.split(separator: ":")
        guard roomId.starts(with: "!"),
              toks.count == 2,
              let first = toks.first,
              let last = toks.last,
              first.count > 1,
              last.count > 3,
              last.contains(".")
        else {
            return false
        }
        return true
    }
    
    init?(_ roomId: String)  {
        guard RoomId.validate(roomId) else {
            return nil
        }
        let toks = roomId.split(separator: ":")
        guard let roomPart = toks.first,
              let domainPart = toks.last
        else {
            return nil
        }
        self.opaqueId = String(roomPart.dropFirst(1))
        self.domain = String(domainPart)
    }
    
    init(from decoder: Decoder) throws {
        let roomId = try String(from: decoder)
        guard let me: RoomId = .init(roomId)
        else {
            let msg = "Invalid room id"
            throw Matrix.Error(msg)
        }
        self = me
    }
    
    func encode(to encoder: Encoder) throws {
        try self.description.encode(to: encoder)
    }
    
    var description: String {
        "!\(opaqueId):\(domain)"
    }

    static func == (lhs: RoomId, rhs: RoomId) -> Bool {
        lhs.description == rhs.description
    }
}
