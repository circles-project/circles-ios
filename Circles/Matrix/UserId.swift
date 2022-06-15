//
//  UserId.swift
//  
//
//  Created by Charles Wright on 5/19/22.
//

import Foundation
    
struct UserId: LosslessStringConvertible, Codable, Equatable, Hashable {
    let username: String
    let domain: String
    
    private static func validate(_ userId: String) -> Bool {
        let toks = userId.split(separator: ":")
        guard userId.starts(with: "@"),
              toks.count == 2,
              let first = toks.first,
              first.count > 1,
              let last = toks.last,
              last.count > 3,
              last.contains(".")
        else {
            return false
        }
        return true
    }
    
    init?(_ userId: String) {
        guard UserId.validate(userId) else {
            //let msg = "Invalid user id"
            //throw Matrix.Error(msg)
            return nil
        }
        let toks = userId.split(separator: ":")
        guard let userPart = toks.first,
              let domainPart = toks.last
        else {
            //let msg = "Invalid user id"
            //throw Matrix.Error(msg)
            return nil
        }
        self.username = String(userPart)
        self.domain = String(domainPart)
    }
    
    init(from decoder: Decoder) throws {
        let userId = try String(from: decoder)
        guard let me: UserId = .init(userId)
        else {
            let msg = "Invalid user id"
            throw Matrix.Error(msg)
        }
        self = me
    }
    
    func encode(to encoder: Encoder) throws {
        try self.description.encode(to: encoder)
    }

    var description: String {
        "\(username):\(domain)"
    }
    
    static func == (lhs: UserId, rhs: UserId) -> Bool {
        lhs.description == rhs.description
    }

    func hash(into hasher: inout Hasher) {
        self.description.hash(into: &hasher)
    }
}

