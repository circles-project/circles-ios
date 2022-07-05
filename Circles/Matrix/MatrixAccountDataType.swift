//
//  MatrixAccountDataType.swift
//  Circles
//
//  Created by Charles Wright on 6/27/22.
//

import Foundation

enum MatrixAccountDataType: Codable {
    case mIdentityServer // "m.identity_server"
    case mFullyRead // "m.fully_read"
    case mDirect // "m.direct"
    case mIgnoredUserList
    case mSecretStorageKey(String) // "m.secret_storage.key.[key ID]"
    
    init(from decoder: Decoder) throws {
        let string = try String(from: decoder)
        
        switch string {
        case "m.identity_server":
            self = .mIdentityServer
            return
        case "m.fully_read":
            self = .mFullyRead
            return
            
        case "m.direct":
            self = .mDirect
            return
            
        case "m.ignored_user_list":
            self = .mIgnoredUserList
            return
            
        default:
            
            // OK it's not one of the "normal" ones.  Is it one of the weird ones?
            if string.starts(with: "m.secret_storage.key.") {
                guard let keyId = string.split(separator: ".").last
                else {
                    let msg = "Couldn't get key id for m.secret_storage.key"
                    print(msg)
                    throw Matrix.Error(msg)
                }
                self = .mSecretStorageKey(String(keyId))
            }
            
            // If we're still here, then we have *no* idea what to do with this thing.
            
            let msg = "Failed to decode MatrixAccountDataType from string [\(string)]"
            print(msg)
            throw Matrix.Error(msg)
        }
    }
}
