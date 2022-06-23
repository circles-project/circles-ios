//
//  MatrixDevice.swift
//
//
//  Created by Charles Wright on 5/12/22.
//

import Foundation

class MatrixCryptoDevice: ObservableObject, Decodable {
    let deviceId: String
    var id: String {
        deviceId
    }
    @Published var displayName: String?
    
    var algorithms: [String]
    
    @Published var keys: [String: String]
    var signatures: [UserId: [String: String]] // user_id -> key_id -> signature bytes
    
    let userId: UserId
    
    // FIXME: Commenting this out entirely until we know how to do it correctly
    //@Published var verified: Bool
    
    // NOTE: Some of the elements here are not part of the Matrix spec.
    // So the coding keys tell the coders which parts should be included in the JSON
    enum CodingKeys: String, CodingKey {
        case deviceId
        case algorithms
        case keys
        case signatures
        case userId
        case unsigned
    }

    /*
    func encode(to encoder: Encoder) throws {
        <#code#>
    }
    */
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.deviceId = try container.decode(String.self, forKey: .deviceId)
        self.algorithms = try container.decode([String].self, forKey: .algorithms)
        self.keys = try container.decode([String:String].self, forKey: .keys)
        self.signatures = try container.decode([UserId:[String:String]].self, forKey: .signatures)
        
        struct Unsigned: Codable {
            //var userId: UserId            // As of v1.3, the Unsigned object contains the displayname, but NOT the userId.  Did this change since v1.2???
            var deviceDisplayName: String?
        }
        if let unsigned: Unsigned = try? container.decode(Unsigned.self, forKey: .unsigned) {
            self.displayName = unsigned.deviceDisplayName
        }
        
        self.userId = try container.decode(UserId.self, forKey: .userId)
        
        // FIXME: Oh gee, how do we tell whether this device counts as "verified" ???
        // I guess we have to go through and check a bunch of signatures.. :-(
        // Commenting out the whole `verified` idea until we know how to do it right
    }
}

